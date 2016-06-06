import Immutable from 'immutable';

import actionTypes from './userConstants';

// this is the default state that would be used if one were not passed into the store
export const $$initialState = Immutable.fromJS({
  editMode: false,
});

export default function userReducer($$state = $$initialState, action) {
  const { type } = action;

  switch (type) {
    case actionTypes.USER_EDIT_MODE_TOGGLE:
      return $$state.set('editMode', !$$state.editMode);

    default:
      return $$state;
  }
}

