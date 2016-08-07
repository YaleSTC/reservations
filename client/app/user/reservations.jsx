import React from 'react';

const Item = ({ title, num, icon }) => {
  return (
    <div className="col-md-6" style={{fontSize: '32.5px'}}>
      <h4>{title}</h4>
      <div>
        <i className={`fa fa-${icon}`}/> {num}
      </div>
    </div>
  );
}

const Reservations = ({ counts }) => {
  const missed = counts.hasOwnProperty('missed')
    ? <Item title="Missed" num={counts.missed} icon="minus-circle" />
    : null;
  return (
    <div>
      <Item title="Checked Out" num={counts.checked_out} icon="camera-retro" />
      <Item title="Overdue" num={counts.overdue} icon="exclamation-circle" />
      <Item title="Future" num={counts.future} icon="list-alt" />
      <Item title="Past" num={counts.past} icon="clock-o" />
      <Item title="Past Overdue" num={counts.past_overdue} icon="thumbs-down" />
      {missed}
    </div>
  );
}

export default Reservations
