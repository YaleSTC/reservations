// This file is our manifest of all reducers for the app.
import userReducer from './user/userReducer';
import { $$initialState as $$userState } from './user/userReducer';

export default {
  $$userStore: userReducer,
};

export const initialStates = {
  $$userState,
};

