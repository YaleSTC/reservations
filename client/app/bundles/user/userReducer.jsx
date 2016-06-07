import React, { PropTypes } from 'react';

const initialState = {
  editMode: false,
  user: null
}

export default function userReducer(state = initialState, action) {
  switch (action.type) {
    case 'SET_USER':
      return {
        ...state,
        user: action.user
      };
    case 'TOGGLE_EDIT_MODE':
      const user = action.user;
      if (state.editMode) {
        $.ajax({
          type: 'PUT',
          url: `/users/${user.id}`,
          data: { user: user },
          dataType: 'json',
        });
      }
      return {
        ...state,
        editMode: !state.editMode,
        user: user
      };
    case 'CANCEL_EDIT_MODE':
      return {
        ...state,
        editMode: false
      };
    default:
      return state;
  }
}
