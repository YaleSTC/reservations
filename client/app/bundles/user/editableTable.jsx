import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const Item = ({ title, text }) => {
  return (
    <div>
      <dt>{title}</dt>
      <dd>{text}</dd>
    </div>
  );
}

const EditableItem = ({ title, text }) => {
  return (
    <div>
      <dt>{title}</dt>
      <dd><input type="text" value={text} /></dd>
    </div>
  );
}

const EditableTable = ({ user, editing }) => {
  const LocalItem = editing ? EditableItem : Item;
  const nickname = user.nickname === '' ? '(none)' : `${user.nickname}`;
  const phone = user.phone === '' ? '(none)' : `${user.phone}`;

  return (
    <div className="row">
      <dl id="user_info" className="dl-horizontal">
        <div className="well">
          <LocalItem title="Name" text={`${user.first_name} ${user.last_name}`} />
          <LocalItem title="Nickname" text={nickname} />
          <LocalItem title="Phone" text={phone} />
          <LocalItem title="Email" text={`${user.email}`} />
          <LocalItem title="Affiliation" text={`${user.affiliation}`} />
        </div>
      </dl>
    </div>
  );
}

const mapStateToProps = (state) => {
  return {
    user: state.user,
    editing: state.editMode,
  }
}

export default connect(mapStateToProps)(EditableTable)
