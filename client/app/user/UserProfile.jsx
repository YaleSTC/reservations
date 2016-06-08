import React from 'react';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
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

