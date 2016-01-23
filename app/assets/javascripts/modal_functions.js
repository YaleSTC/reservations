function userModalLoad ()
{
	if ($('div.modal-body form').length) // check if there is a form? if so the DOM tree needs to be sorted
	{
		// create a DOM order acourding to the desired order
		// first input to first div
		$('form#new_user').next().next().appendTo($('form#new_user').next());
		// user name
		$('input#user_username').appendTo($('div.user_username'));
		// first name
		for (var i=0; i<3; i++)
		{
			$('div.user_first_name').next().appendTo($('div.user_first_name'));
		}
		// last name
		for (var i=0; i<3; i++)
		{
			$('div.user_last_name').next().appendTo($('div.user_last_name'));
		}
		// phone number
		for (var i=0; i<3; i++)
		{
			$('div.user_phone').next().appendTo($('div.user_phone'));
		}
		// email
		for (var i=0; i<3; i++)
		{
			$('div.user_email').next().appendTo($('div.user_email'));
		}
		// affiliation
		for (var i=0; i<3; i++)
		{
			$('div.user_affiliation').next().appendTo($('div.user_affiliation'));
		}
		// buttons
		for (var i=0; i<2; i++)
		{
			$('div#userModalButtons').next().appendTo($('div#userModalButtons'));
		}
		// collect all divs to the form
		for (var i=0; i<8; i++)
		{
			$('form#new_user').next().appendTo($('form#new_user'));
		}
	};
};
