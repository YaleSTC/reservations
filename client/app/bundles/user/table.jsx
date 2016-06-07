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

const Table = ({ user }) => {
  return (
    <dl id="user_info" class="dl-horizontal col-md-6">
      <div class="well">
        <Item title="Name" text={`${user.first_name} ${user.last_name}`} />
        <Item title="Nickname" text={`${user.nickname}`} />
      </div>
    </dl>
  );
}

const mapStateToProps = (state) => {
  return {
    user: state.user
  }
}

export default connect(mapStateToProps)(Table)

