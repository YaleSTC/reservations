import React, { PropTypes } from 'react';

export default class UserInfoTable extends React.Component {
  static propTypes = {
    // If you have lots of data or action properties, you should consider grouping them by
    // passing two properties: "data" and "actions".
    toggleEditMode: PropTypes.func.isRequired,
    editMode: PropTypes.bool.isRequired,
    user: PropTypes.object.isRequired,
  };

  // React will automatically provide us with the event `e`
  handleChange(e) {
    const editMode = e.target.value;
    this.props.toggleEditMode(editMode);
  }

  render() {
    const user = this.state.user
    return (
      <dl id="user_info" class="dl-horizontal col-md-6">
        <div class="well">
          <dt>First Name</dt>
          <dd> user.first_name </dd>

          <dt>Last Name</dt>
          <dd> user.last_name </dd>

          <dt>Nickname</dt>
          <dd> user.nickname </dd>

          <dt>Phone</dt>
          <dd> user.phone </dd>

          <dt>Email</dt>
          <dd> mail_to user.email, user.email </dd>

          <dt>Affiliation</dt>
          <dd> user.affiliation </dd>
        </div>
      </dl>
    );
  }
}

