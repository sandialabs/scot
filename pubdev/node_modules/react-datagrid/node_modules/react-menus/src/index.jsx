'use strict';

var MenuClass = require('./Menu')

var MenuItem      = require('./MenuItem')
var MenuItemCell  = require('./MenuItemCell')
var MenuSeparator = require('./MenuSeparator')

MenuClass.Item      = MenuItem
MenuClass.Item.Cell = MenuItemCell
MenuClass.ItemCell  = MenuItemCell
MenuClass.Separator = MenuSeparator

module.exports = MenuClass