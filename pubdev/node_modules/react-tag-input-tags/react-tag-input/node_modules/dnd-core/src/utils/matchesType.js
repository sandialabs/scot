import isArray from 'lodash/lang/isArray';

export default function matchesType(targetType, draggedItemType) {
  if (isArray(targetType)) {
    return targetType.some(t => t === draggedItemType);
  } else {
    return targetType === draggedItemType;
  }
}