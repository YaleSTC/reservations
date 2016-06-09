import React from 'react';
import { connect } from 'react-redux';
import EditableTable from './editableTable';
import Table from './table';
import Reservations from './reservations';

const UserInfo = ({ user, canEdit, editing, onEditClick }) => {
  const table = editing ? <EditableTable /> : <Table />;
  const save = editing 
    ? <button form="userForm" type="submit" className="btn btn-primary">Save</button>
    : null;
  const color = editing ? 'default' : 'primary';
  const text = editing ? 'Cancel' : 'Edit';
  return (
    <div className="row">
      <div className='col-md-6'>
        <div className="well">
          <div className='row'>
            {table}
          </div>
          <div className="row">
            <div className="col-md-offset-1 btn-group">
              {save}
              <button 
                className={`btn btn-${color}`}
                onClick={() => { onEditClick() }}>
                {text}
              </button>
            </div>
          </div>
        </div>
      </div>
      <div className="col-md-6">
        <Reservations counts={user.reservation_counts} />
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
  return { onEditClick: () => { dispatch({ type: 'TOGGLE_EDIT_MODE' }) }, }
}

export default connect(mapStateToProps, mapDispatchToProps)(UserInfo)
