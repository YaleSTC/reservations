import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const Form = ({ user, onSave, id }) => {
  let firstName, lastName, nickname, phone, email, affiliation, tos;

  return (
    <div>
      <form id="userForm" className="form-horizontal" onSubmit={(e) => {
        e.preventDefault();
        onSave({
          first_name: firstName.value,
          last_name: lastName.value,
          nickname: nickname.value,
          phone: phone.value,
          email: email.value,
          affiliation: affiliation.value,
          terms_of_service_accepted: tos.value,
        })
      }}>
      <div className="form-group">
        <label className="control-label col-sm-4"> First Name </label>
        <div className="col-sm-8">
          <input type="text" class="form-control" 
            defaultValue={`${user.first_name}`}
            ref={node => { firstName = node } }/>
        </div>
      </div>
      <div className="form-group">
        <label className="control-label col-sm-4"> Last Name </label>
        <div className="col-sm-8">
          <input type="text" class="form-control" 
            defaultValue={`${user.last_name}`}
            ref={node => { lastName = node } }/>
        </div>
      </div>
      <div className="form-group">
        <label className="control-label col-sm-4"> Nickname </label>
        <div className="col-sm-8">
          <input type="text" class="form-control" 
            defaultValue={`${user.nickname}`}
            ref={node => { nickname = node } }/>
        </div>
      </div>
      <div className="form-group">
        <label className="control-label col-sm-4"> Phone </label>
        <div className="col-sm-8">
          <input type="text" class="form-control" 
            defaultValue={`${user.phone}`}
            ref={node => { phone = node } }/>
        </div>
      </div>
      <div className="form-group">
        <label className="control-label col-sm-4"> Email </label>
        <div className="col-sm-8">
          <input type="text" class="form-control" 
            defaultValue={`${user.email}`}
            ref={node => { email = node } }/>
        </div>
      </div>
      <div className="form-group">
        <label className="control-label col-sm-4"> Affiliation </label>
        <div className="col-sm-8">
          <input type="text" class="form-control" 
            defaultValue={`${user.affiliation}`}
            ref={node => { affiliation = node } }/>
        </div>
      </div>
      <div className="form-group">
        <div className="col-sm-offset-4 col-sm-8">
          <div className="checkbox">
            <label>
              <input 
                type="checkbox" checked={user.terms_of_service_accepted}
                ref={node => { tos = node } }
              />
              Accept the <a href='/terms_of_service'> TOS </a>
            </label>
          </div>
        </div>
      </div>
    </form>
  </div>
  );
}

const mapStateToProps = (state) => ({
  user: state.user,
});

const mapDispatchToProps = (dispatch) => {
  return {
    onSave(changes) { dispatch({ type: 'UPDATE_USER', changes: changes }) },
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Form)
