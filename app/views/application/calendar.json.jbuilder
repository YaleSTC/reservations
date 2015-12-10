# colors (currently "borrowed" from Bootstrap)
overdue_clr = '#d9534f'
reserved_clr = '#337ab7'
checked_out_clr = '#5bc0de'
returned_clr = '#5cb85c'
missed_clr = '#888'

# generate json
json.array!(@calendar_res) do |res|
  json.extract! res, :id
  json.title res.send(@name_method).name
  json.start res.start_date
  json.end res.end_date + 1.day
  json.backgroundColor res.overdue ? overdue_clr : eval("#{res.status}_clr")
  json.borderColor res.overdue ? overdue_clr : eval("#{res.status}_clr")
  json.allDay true
  json.url reservation_url(res, format: :html)
  json.hasItem !res.equipment_item.nil?
  json.location res.equipment_item.name unless res.equipment_item.nil?
end
