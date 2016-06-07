import React, { PropTypes } from 'react';
import ReactOnRails from 'react-on-rails';
import { compose, createStore, applyMiddleware, combineReducers } from 'redux';
import { bindActionCreators } from 'redux';
import thunkMiddleware from 'redux-thunk';
import { Provider } from 'react-redux';
import { connect } from 'react-redux';
import mirrorCreator from 'mirror-creator';
import Immutable from 'immutable';

import EditableTable from './editableTable'

const UserInfo = ({ user, editing, onEditClick, onCancelClick }) => {
  const color = editing ? 'success' : 'primary';
  const text = editing ? 'Save' : 'Edit User';
  const cancel = editing 
    ? <button className='btn btn-default' onClick={() => { onCancelClick() }}> Cancel </button>
    : null;

  return (
    <div className='col-md-6'>
      <EditableTable />
      <div className="row btn-group">
        <button className={`btn btn-${color}`} onClick={() => { onEditClick(user) }}> {text} </button>
        {cancel}
      </div>
    </div>
  );
}

const mapStateToProps = (state) => {
  return {
    editing: state.editMode,
    user: state.user,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onEditClick: (user) => {
      dispatch({ type: 'TOGGLE_EDIT_MODE', user: user }) },
    onCancelClick: () => { dispatch({ type: 'CANCEL_EDIT_MODE' }) },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(UserInfo)
