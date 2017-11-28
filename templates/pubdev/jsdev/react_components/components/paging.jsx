var React = require('react')
var PaginationToolbar = React.createFactory(require('react-datagrid/lib/PaginationToolbar'));
var assign = require('object-assign');

function clamp(value, min, max) {
    return value < min ? min : value > max ? max : value;
}

var Page = React.createClass({
   

    getInitialState: function(){
        var defaultpage = 1; 
        if (this.props.defaultpage != undefined) {
            defaultpage = this.props.defaultpage
        }
        if (defaultpage == 0) { defaultpage = 1}
        return {defaultpage: defaultpage, defaultPageSize: this.props.defaultPageSize}

    },
    preparePaging: function preparePaging(props) {
        props.pagination = true
        if (props.pagination) {
            props.pageSize = this.preparePageSize(props);
            props.minPage = 1;
            props.maxPage = Math.ceil((props.count || 1) / props.pageSize);
            props.page = clamp(this.preparePage(props), props.minPage, props.maxPage);
        }
    },

    preparePageSize: function preparePageSize(props) {
        return props.pageSize;
    },
    isValidPage: function isValidPage(page, props) {
        return page >= 1 && page <= this.getMaxPage(props);
    },

    getMaxPage: function getMaxPage(props) {
        props = props || this.props;

        var count =  props.count || 1;
        var pageSize = this.preparePageSize(props);

        return Math.ceil(count / pageSize);
    },

   clampPage: function clampPage(page) {
        return clamp(page, 1, this.getMaxPage(this.props));
    },

    setPageSize: function setPageSize(pageSize) {
        var stateful;
        var newPage = this.preparePage(this.props);
        var newState = {};
        if (typeof this.props.onPageSizeChange == 'function') {
        }

        if (this.props.PageSize == null) {
            stateful = true;
            this.state.defaultPageSize = pageSize;
            newState.defaultPageSize = pageSize;
            this.scrollTop = 0
        }

        if (!this.isValidPage(newPage, this.props)) {

            newPage = this.clampPage(newPage);

            if (typeof this.props.onPageChange == 'function') {
                this.props.onPageChange(newPage);
            }

            if (this.props.page == null) {
                stateful = true;
                this.state.defaultpage = newPage;
                newState.defaultpage = newPage;
                newState.scrollTop = 0
            }
        }
        if (stateful) {
            if(pageSize == 50 || pageSize == 5 || pageSize == 10 || pageSize == 20){
                $('.ref-verticalScrollbar').animate({
                scrollTop: 0},"fast")
            }
        }
            this.setState(newState);
            this.props.pagefunction({page: this.state.defaultpage, limit: this.state.defaultPageSize})
    },

    preparePage: function preparePage(props) {
        return props.page == null ? this.state.defaultpage : props.page;
    },
    gotoPage: function gotoPage(page) {
        if (typeof this.props.onPageChange == 'function') {
            this.props.onPageChange(page);
        } else {
            this.state.defaultpage = page;
            this.scrollTop = 0
            this.setState({
                defaultpage: page,
                scrollTop: 0
            });
            
            this.props.pagefunction({page: page, limit: this.state.defaultPageSize});
            var cookieName = 'listViewPage'+this.props.type;
            setCookie(cookieName,JSON.stringify({page:page, limit: this.state.defaultPageSize}),1000); 
        }
    },
    render: function(){
        var props = assign({
            minPage: 0,
            maxPage: 0,
            page: this.state.defaultpage,
            pagination:true,
            count: this.props.count,
            pageSize: this.state.defaultPageSize
       }, this.props.paginationToolbarProps )
        this.preparePaging(props)
        var paginationToolbar;
        if (props.pagination) {
            var page = props.page;
            var minPage = props.minPage;
            var maxPage = props.maxPage;
            var paginationToolbarFactory = props.paginationFactory || PaginationToolbar;
            var paginationProps = assign({
                dataCount: props.count,
                page: page,
                pageSize: props.pageSize,
                minPage: minPage,
                maxPage: maxPage,
                onPageChange: this.gotoPage,
                onPageSizeChange: this.setPageSize
                //border: props.style.border
            }, this.props.paginationToolbarProps);

            paginationToolbar = paginationToolbarFactory(paginationProps);

            if (paginationToolbar === undefined) {
                paginationToolbar = PaginationToolbar(paginationProps);
            }
        }
        var topToolbar;
        var bottomToolbar;

        if (paginationToolbar) {
            if (paginationToolbar.props.position == 'top') {
                topToolbar = paginationToolbar;
            } else {
                bottomToolbar = paginationToolbar;
            }
        }

        return (
            React.createElement(
                'div',
                topToolbar,
                bottomToolbar
            ) 
            
        )
    }
})



module.exports = Page
