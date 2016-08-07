import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const Item = ({ title, text }) => {
  return (
    <div className="form-group">
      <label className="col-sm-4 control-label" for="">{title}</label>
      <div className="col-sm-8">
        <p className="form-control-static">{text}</p>
      </div>
    </div>
  );
}

const Table = ({ user }) => {
  const nickname = user.nickname === '' ? '(none)' : `${user.nickname}`;
  const phone = user.phone === '' ? '(none)' : `${user.phone}`;
  return (
    <form className="form-horizontal">
      <Item title="Name" text={`${user.first_name} ${user.last_name}`} />
      <Item title="Nickname" text={nickname} />
      <Item title="Phone" text={phone} />
      <Item title="Email" text={`${user.email}`} />
      <Item title="Affiliation" text={`${user.affiliation}`} />
    </form>
  );
}

const mapStateToProps = (state) => ({
  user: state.user
});

export default connect(mapStateToProps)(Table)

