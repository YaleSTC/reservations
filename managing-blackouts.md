---
layout: admin-page
title: Managing Blackouts
permalink: /user-doc/blackouts/
---
Blackouts are periods of time when your users cannot check their reserved equipment either in or out. (They can still make a reservation for a later time.) These are useful when your office is closed, or unable to process check-ins and check-outs for some other reason.

*Reservations* implements two kinds of blackouts: **one-off** and **recurring**. You would use one-off blackouts for Independence Day, and recurring blackouts for weekends.

It allows either kind of blackout to be *notice-only*. This means that when a user attempts to create a reservation that either begins or ends on one a day of notice-only blackout, they are served a notice. This is useful, for example, if your office closes earlier than usual on some day.

## Managing Blackouts

To create, edit, or delete a blackout, navigate to `Admin > Blackouts`.

![image](/reservations/images/blackout-index.png)

### Creating a One-off Blackout

If you want to create a **one-off** blackout, click on `New Blackout`. On the following page, select the date range for which you wish reservations to be affected.

![image](/reservations/images/blackout-normal.png)


### Creating a Recurring Blackout

If you want to create a **recurring** blackout, click on `New Recurring Blackout`. On the following page, select the date range for which you wish the blackouts to recur, and the weekdays you wish to be affected by the blackout.

![image](/reservations/images/blackout-recurring.png)