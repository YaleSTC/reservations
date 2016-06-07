import React, { PropTypes } from 'react';
import { connect } from 'react-redux';

const EditableItem = ({ editing, title, text }) => {
  const item = editing ? <input type="text" placeholder={text} /> : text
  return (
    <div>
      <dt>{title}</dt>
      <dd>{item}</dd>
    </div>
  );
}

const mapStateToProps = (state) => {
  return {
    editing: state.editing,
  }
}

export default connect(mapStateToProps)(EditableItem)

