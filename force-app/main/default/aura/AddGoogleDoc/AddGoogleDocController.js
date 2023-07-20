({

	handleGoogleDocRedirect: function(component, event, helper) {
		window.open("https://docs.google.com/a/n4l.co.nz", '_blank');
	},

	handleSave : function (component, event, helper) {

		var inputFields = component.find("ui_inputs");

		var hasErrors = false;

		for (var key in inputFields) {
			
			var input = inputFields[key];

			if (!input.get('v.value')) {

				input.set("v.errors", [{message:"Field is required"}]);

				hasErrors = true;
			} else {
				input.set("v.errors", null);
			}
		}

		if (hasErrors) return;

		var saveDoc = component.get('c.saveGoogleDoc');
		var name = inputFields[0].get('v.value');
		var url = inputFields[1].get('v.value');

		saveDoc.setParams({'name' : name, 'parentId' : component.get('v.recordId'), 'url' : url});

		saveDoc.setCallback(this, function(response) {

			var toastEvent = $A.get("e.force:showToast");
			var returnedMessage = response.getReturnValue();
			var isSuccess = response.getReturnValue() === 'success';

			toastEvent.setParams({
				title: isSuccess ? 'Success!' : 'Error!',
				message: isSuccess ? 'Google doc has been linked' : 'An error has occured, ' + returnedMessage,
				type: isSuccess ? 'success' : 'error'
			});

			if (isSuccess) {
				for (var key in inputFields) {
					
					var input = inputFields[key];
					input.set('v.value', '');
				}
			}
			
			toastEvent.fire();
			$A.get('e.force:refreshView').fire();
		});

		$A.enqueueAction(saveDoc);
	},

	handleCancel : function (component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})