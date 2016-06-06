import actionTypes from './userConstants';

export function toggleEditMode() {
  return {
    type: actionTypes.USER_EDIT_MODE_TOGGLE,
  };
}

