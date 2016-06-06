import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Immutable from 'immutable';
import UserInfoTable from './userInfoTable';
import * as userActionCreators from './userActionCreators';

function select(state) {
  return { $$userStore: state.$$userStore };
}

const User = (props) => {
  const { dispatch, $$userStore } = props;
  const actions = bindActionCreators(userActionCreators, dispatch);
  const { toggleEditMode } = actions;
  const editMode = $$userStore.get('editMode');

  return (
    <UserInfoTable {...{ toggleEditMode, editMode }} />
  );
};

User.propTypes = {
  dispatch: PropTypes.func.isRequired,

  $$userStore: PropTypes.instanceOf(Immutable.Map).isRequired,
};

// Don't forget to actually use connect!
export default connect(select)(User);

