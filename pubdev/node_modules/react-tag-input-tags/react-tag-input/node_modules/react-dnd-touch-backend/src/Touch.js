/**
 * Copyright 2015, Yahoo Inc.
 * Copyrights licensed under the MIT License. See the accompanying LICENSE file for terms.
 */
'use strict';

import invariant from 'invariant';

function getEventClientTouchOffset (e) {
    if (e.targetTouches.length === 1) {
        return getEventClientOffset(e.targetTouches[0]);
    }
}

function getEventClientOffset (e) {
    if (e.targetTouches) {
        return getEventClientTouchOffset(e);
    } else {
        return {
            x: e.clientX,
            y: e.clientY
        };
    }
}

const ELEMENT_NODE = 1;
function getNodeClientOffset (node) {
    const el = node.nodeType === ELEMENT_NODE
        ? node
        : node.parentElement;

    if (!el) {
        return null;
    }

    const { top, left } = el.getBoundingClientRect();
    return { x: left, y: top };
}

const eventNames = {
    mouse: {
        start: 'mousedown',
        move: 'mousemove',
        end: 'mouseup'
    },
    touch: {
        start: 'touchstart',
        move: 'touchmove',
        end: 'touchend'
    }
};

export class TouchBackend {
    constructor (manager, options = {}) {
        options = {
            enableTouchEvents: true,
            enableMouseEvents: false,
            ...options
        };

        this.actions = manager.getActions();
        this.monitor = manager.getMonitor();
        this.registry = manager.getRegistry();

        this.sourceNodes = {};
        this.sourceNodeOptions = {};
        this.sourcePreviewNodes = {};
        this.sourcePreviewNodeOptions = {};
        this.targetNodes = {};
        this.targetNodeOptions = {};
        this.listenerTypes = [];
        this._mouseClientOffset = {};

        if (options.enableMouseEvents) {
            this.listenerTypes.push('mouse');
        }

        if (options.enableTouchEvents) {
            this.listenerTypes.push('touch');
        }

        this.getSourceClientOffset = this.getSourceClientOffset.bind(this);
        this.handleTopMoveStart = this.handleTopMoveStart.bind(this);
        this.handleTopMoveStartCapture = this.handleTopMoveStartCapture.bind(this);
        this.handleTopMoveCapture = this.handleTopMoveCapture.bind(this);
        this.handleTopMoveEndCapture = this.handleTopMoveEndCapture.bind(this);
    }

    setup () {
        if (typeof window === 'undefined') {
            return;
        }

        invariant(!this.constructor.isSetUp, 'Cannot have two Touch backends at the same time.');
        this.constructor.isSetUp = true;

        this.addEventListener(window, 'start', this.handleTopMoveStartCapture, true);
        this.addEventListener(window, 'start', this.handleTopMoveStart);
        this.addEventListener(window, 'move',  this.handleTopMoveCapture, true);
        this.addEventListener(window, 'end',   this.handleTopMoveEndCapture, true);
    }

    teardown () {
        if (typeof window === 'undefined') {
            return;
        }

        this.constructor.isSetUp = false;
        this._mouseClientOffset = {};

        this.removeEventListener(window, 'start', this.handleTopMoveStartCapture, true);
        this.removeEventListener(window, 'start', this.handleTopMoveStart);
        this.removeEventListener(window, 'move',  this.handleTopMoveCapture, true);
        this.removeEventListener(window, 'end',   this.handleTopMoveEndCapture, true);

        this.uninstallSourceNodeRemovalObserver();
    }

    addEventListener (subject, event, handler, capture) {
        this.listenerTypes.forEach(function (listenerType) {
            subject.addEventListener(eventNames[listenerType][event], handler, capture);
        });
    }

    removeEventListener (subject, event, handler, capture) {
        this.listenerTypes.forEach(function (listenerType) {
            subject.removeEventListener(eventNames[listenerType][event], handler, capture);
        });
    }

    connectDragSource (sourceId, node, options) {
        const handleMoveStart = this.handleMoveStart.bind(this, sourceId);
        this.sourceNodes[sourceId] = node;

        this.addEventListener(node, 'start', handleMoveStart);

        return () => {
            delete this.sourceNodes[sourceId];
            this.removeEventListener(node, 'start', handleMoveStart);
        };
    }

    connectDragPreview (sourceId, node, options) {
        this.sourcePreviewNodeOptions[sourceId] = options;
        this.sourcePreviewNodes[sourceId] = node;

        return () => {
            delete this.sourcePreviewNodes[sourceId];
            delete this.sourcePreviewNodeOptions[sourceId];
        };
    }

    connectDropTarget (targetId, node) {
        this.targetNodes[targetId] = node;

        return () => {
            delete this.targetNodes[targetId];
        };
    }

    getSourceClientOffset (sourceId) {
        return getNodeClientOffset(this.sourceNodes[sourceId]);
    }

    handleTopMoveStartCapture (e) {
        this.moveStartSourceIds = [];
    }

    handleMoveStart (sourceId) {
        this.moveStartSourceIds.unshift(sourceId);
    }

    handleTopMoveStart (e) {
        // Don't prematurely preventDefault() here since it might:
        // 1. Mess up scrolling
        // 2. Mess up long tap (which brings up context menu)
        // 3. If there's an anchor link as a child, tap won't be triggered on link

        const clientOffset = getEventClientOffset(e);
        if (clientOffset) {
            this._mouseClientOffset = clientOffset;
        }
    }

    handleTopMoveCapture (e) {
        const { moveStartSourceIds } = this;
        const clientOffset = getEventClientOffset(e);

        if (!clientOffset) {
            return;
        }


        // If we're not dragging and we've moved a little, that counts as a drag start
        if (
            !this.monitor.isDragging() &&
            this._mouseClientOffset.hasOwnProperty('x') &&
            moveStartSourceIds &&
            (
                this._mouseClientOffset.x !== clientOffset.x ||
                this._mouseClientOffset.y !== clientOffset.y
            )
        ) {
            this.moveStartSourceIds = null;
            this.actions.beginDrag(moveStartSourceIds, {
                clientOffset: this._mouseClientOffset,
                getSourceClientOffset: this.getSourceClientOffset,
                publishSource: false
            });
        }

        if (!this.monitor.isDragging()) {
            return;
        }

        const sourceNode = this.sourceNodes[this.monitor.getSourceId()];
        this.installSourceNodeRemovalObserver(sourceNode);
        this.actions.publishDragSource();

        e.preventDefault();

        const matchingTargetIds = Object.keys(this.targetNodes)
            .filter((targetId) => {
                const boundingRect = this.targetNodes[targetId].getBoundingClientRect();
                return clientOffset.x >= boundingRect.left &&
                clientOffset.x <= boundingRect.right &&
                clientOffset.y >= boundingRect.top &&
                clientOffset.y <= boundingRect.bottom;
            });

        this.actions.hover(matchingTargetIds, {
            clientOffset: clientOffset
        });
    }

    handleTopMoveEndCapture (e) {
        if (!this.monitor.isDragging() || this.monitor.didDrop()) {
            this.moveStartSourceIds = null;
            return;
        }

        e.preventDefault();

        this._mouseClientOffset = {};

        this.uninstallSourceNodeRemovalObserver();
        this.actions.drop();
        this.actions.endDrag();
    }

    installSourceNodeRemovalObserver (node) {
        this.uninstallSourceNodeRemovalObserver();

        this.draggedSourceNode = node;
        this.draggedSourceNodeRemovalObserver = new window.MutationObserver(() => {
            if (!node.parentElement) {
                this.resurrectSourceNode();
                this.uninstallSourceNodeRemovalObserver();
            }
        });

        if (!node || !node.parentElement) {
            return;
        }

        this.draggedSourceNodeRemovalObserver.observe(
            node.parentElement,
            { childList: true }
        );
    }

    resurrectSourceNode () {
        this.draggedSourceNode.style.display = 'none';
        this.draggedSourceNode.removeAttribute('data-reactid');
        document.body.appendChild(this.draggedSourceNode);
    }

    uninstallSourceNodeRemovalObserver () {
        if (this.draggedSourceNodeRemovalObserver) {
            this.draggedSourceNodeRemovalObserver.disconnect();
        }

        this.draggedSourceNodeRemovalObserver = null;
        this.draggedSourceNode = null;
    }
}

export default function createTouchBackend (optionsOrManager = {}) {
    const touchBackendFactory = function (manager) {
        return new TouchBackend(manager, optionsOrManager);
    };

    if (optionsOrManager.getMonitor) {
        return touchBackendFactory(optionsOrManager);
    } else {
        return touchBackendFactory;
    }
}
