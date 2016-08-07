import React, { PropTypes } from 'react';

const initialState = {
  editMode: false,
  user: null,
}

export default function userReducer(state = initialState, action) {
  switch (action.type) {
    case 'SET_USER':
      return {
        ...state,
        user: action.user,
      };
    case 'TOGGLE_EDIT_MODE':
      return {
        ...state,
        editMode: !state.editMode,
      };
    case 'UPDATE_USER':
      const user = state.user;
      const changes = action.changes
      if (state.editMode) {
        $.ajax({
          type: 'PUT',
          url: `/users/${user.id}`,
          data: { user: changes },
          dataType: 'json',
        });
      }
      return {
        ...state,
        editMode: !state.editMode,
        user: { ...user, ...changes }
      };
    default:
      return state;
  }
}
