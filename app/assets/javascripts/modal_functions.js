function userModalLoad ()
{
	if ($('div.modal-body form').length) // check if there is a form? if so the DOM tree needs to be sorted
	{
		// create a DOM order acourding to the desired order
		// the diffret form field divs - all of these have 3 children
		var formFields = ['div.user_first_name',
											'div.user_last_name',
											'div.user_phone',
											'div.user_email',
											'div.user_affiliation'];
		// first input to first div
		$('form#new_user').next().next().appendTo($('form#new_user').next());
		// user name
		$('input#user_username').appendTo($('div.user_username'));
		// form fields
		for (var j=0; j<formFields.length; j++)
		{
			for (var i=0; i<3; i++)
			{
				$(formFields[j]).next().appendTo($(formFields[j]));
			}
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
