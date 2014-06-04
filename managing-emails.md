---
layout: admin-page
title: Managing Emails
permalink: /user-doc/emails/
---
*Reservations* can send e-mails to patrons when the following events arise:

* Check-in date for a checked-out piece of equipment is coming up;
* Patrons missed their check-in date and their equipment is overdue;
* Patrons missed their check-out date and their reservation has been deleted.

You can set the content of the e-mails that are sent out in `Admin > Settings`, under the heading `Emails`.

![image](/reservations/images/emails.png)

## Format
You can use the following content placeholders in the e-mail templates you create:

| Placeholder   	| Meaning       |
| ------------- 	|:-------------:|
| @user@       		| The full name of the user. |
| @equipment_list@	| The list of equipment that user either has reserved, missed, overdue, or checked out. |
| @reservation_id@	| The id number of the reservation. |
| @department_name@	| The department name set above. |
| @start_date@ 		| The start date for the reservation. |
| @return_date@		| The due date for the reservation. |
| @late_fee@		| The daily late fee for the equipment model in the reservation. |

These are also listed on the `Admin > Settings` page.

No advanced formatting is supported at this time.

## Troubleshooting
### The e-mails aren't sending.
*Pending*

### E-mails are sending for no good reason.
*Pending*