import React, { PropTypes } from 'react';
import ReactOnRails from 'react-on-rails';
import { compose, createStore, applyMiddleware, combineReducers } from 'redux';
import { bindActionCreators } from 'redux';
import thunkMiddleware from 'redux-thunk';
import { Provider } from 'react-redux';
import { connect } from 'react-redux';
import mirrorCreator from 'mirror-creator';
import Immutable from 'immutable';

const initialState = {
  editMode: false,
  user: null
}

const userReducer = (state = initialState, action) => {
  switch (action.type) {
    case 'SET_USER':
      return {
        ...state,
        user: action.user
      };
    case 'TOGGLE_EDIT_MODE':
      return {
        ...state,
        editMode: !state.editMode
      };
    default:
      return state;
  }
};

const store = createStore(userReducer);

class UserInfo extends React.Component {
  render() {
    let editing = this.props.editMode;
    let color = editing ? 'red' : '';
    return (
      <div>
        <button onClick={() => {
          store.dispatch({
            type: 'TOGGLE_EDIT_MODE'
          });
        }}>
          Edit
        </button>
        {EditableTable(this.props.user, this.props.editMode)}
      </div>
    );
  }
}

const EditableTable = (user, editMode) => {
  return (
    <dl id="user_info" class="dl-horizontal col-md-6">
      <div class="well">
        <dt>First Name</dt>
        <dd> {user.first_name} </dd>

        <dt>Last Name</dt>
        <dd> {user.last_name} </dd>

        <dt>Nickname</dt>
        <dd> {user.nickname.blank} </dd>

        <dt>Phone</dt>
        <dd> {user.phone} </dd>

        <dt>Email</dt>
        <dd> {user.email} </dd>

        <dt>Affiliation</dt>
        <dd> {user.affiliation} </dd>
      </div>
    </dl>
  );
}

export default (props, _railsContext) => {
  if (store.getState().user === null) {
    store.dispatch({
      type: 'SET_USER',
      user: props
    });
  }
  
  const reactComponent = (
    <div>
      <h3> OLD CODE </h3>
      <UserInfo
        user={store.getState().user}
        editMode={store.getState().editMode}
      />
    </div>
  );
  return reactComponent;
};
