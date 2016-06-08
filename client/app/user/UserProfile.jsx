import React, { PropTypes } from 'react';
import ReactOnRails from 'react-on-rails';
import { compose, createStore, applyMiddleware, combineReducers } from 'redux';
import { bindActionCreators } from 'redux';
import thunkMiddleware from 'redux-thunk';
import { Provider } from 'react-redux';
import { connect } from 'react-redux';
import mirrorCreator from 'mirror-creator';
import Immutable from 'immutable';

import User from './userContainer';
import userReducer from './userReducer';


export default (props, _railsContext) => {
  const store = createStore(userReducer);
  if (store.getState().user === null) {
    store.dispatch({
      type: 'SET_USER',
      user: props
    });
  }
  
  const reactComponent = (
    <Provider store={store}>
      <User />
    </Provider>
  );
  return reactComponent;
};

