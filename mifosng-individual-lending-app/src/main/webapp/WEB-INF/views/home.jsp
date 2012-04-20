<%@ page session="true" %>
<%@ page trimDirectiveWhitespaces="true" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>
<c:set var="pageTitle" scope="request"><spring:message code="page.home.title"/></c:set>
<!DOCTYPE html>
<html lang="en">
<head>
<jsp:include page="common-head.jsp" />
<c:url value="/" var="rootContext" />
<script>
$(document).ready(function() {

	$.views.registerHelpers({
		
		money: function(monetaryObj) {
			
			Globalize.culture().numberFormat.currency.symbol = monetaryObj.displaySymbol;
			
			var digits = monetaryObj.currencyDigitsAfterDecimal.toFixed(0);
			return Globalize.format(monetaryObj.amount, "n" + digits); 
		},
		moneyWithCurrency: function(monetaryObj) {
			
			Globalize.culture().numberFormat.currency.symbol = monetaryObj.displaySymbol;
			
			var digits = monetaryObj.currencyDigitsAfterDecimal.toFixed(0);
			return Globalize.format(monetaryObj.amount, "c" + digits); 
		},
		decimal: function(number, digits) {
	      try {
	        return number.toFixed(digits);
	      } catch(e) {
	        return number +"(NaN)";
	      }
	    },
		number: function(number) {
	      try {
	        return number.toFixed(0);
	      } catch(e) {
	        return number +"(NaN)";
	      }
	    },
	    numberGreaterThanZero: function(number) {
		      try {
		    	var num = number.toFixed(0);
		        return num > 0;
		      } catch(e) {
		        return false;
		      }
		    },
	    json: function(obj) {
		      try {
		        return JSON.stringify(obj);
		      } catch(e) {
		        return "" + e;
		      }
		},
		globalDate: function(dateParts) {
		      try {
		    	
		    	  var year = dateParts[0];
		    	  var month = parseInt(dateParts[1]) - 1; // month is zero indexed
		    	  var day = dateParts[2];
		    	  
		    	  var d = new Date();
		    	  d.setFullYear(year,month,day);
		    	  
		    	  return Globalize.format(d,"dd MMMM yyyy");
		      } catch(e) {
		        return "??";
		      }
		},
		globalDateTime: function(dateParts) {
		      try {
		    	  var d = new Date(dateParts);
		    	  
		    	  return Globalize.format(d,"F");
		      } catch(e) {
		        return "??";
		      }
		}
		
	});
	
function handleXhrError(jqXHR, textStatus, errorThrown, templateSelector, placeholderDiv) {
  	if (jqXHR.status === 0) {
	    alert('No connection. Verify application is running.');
  	} else if (jqXHR.status == 401) {
		alert('Unauthorized. [401]');
	} else if (jqXHR.status == 404) {
	    alert('Requested page not found. [404]');
	} else if (jqXHR.status == 405) {
		alert('HTTP verb not supported [405]: ' + errorThrown);
	} else if (jqXHR.status == 500) {
	    alert('Internal Server Error [500].');
	} else if (errorThrown === 'parsererror') {
	    alert('Requested JSON parse failed.');
	} else if (errorThrown === 'timeout') {
	    alert('Time out error.');
	} else if (errorThrown === 'abort') {
	    alert('Ajax request aborted.');
	} else {
		// remove error class from all input fields
		var $inputs = $('#entityform :input');
		
	    $inputs.each(function() {
	        $(this).removeClass("ui-state-error");
	    });
		
	  	$(placeholderDiv).html("");
	  	
	  	var jsonErrors = JSON.parse(jqXHR.responseText);
	  	
	  	var errorArray = new Array();
	  	var arrayIndex = 0;
	  	$.each(jsonErrors, function() {
	  	  var fieldId = '#' + this.field;
	  	  $(fieldId).addClass("ui-state-error");
	  	  
	  	  var errorObj = new Object();
	  	  errorObj.field = this.field;
	  	  errorObj.code = this.code;
	  	  errorObj.message = jQuery.i18n.prop(this.code, this.args);
	  	  errorObj.value = this.value;
	  	  
	  	  errorArray[arrayIndex] = errorObj;
	  	  arrayIndex++
	  	});
	  	
	  	var templateArray = new Array();
	  	var templateErrorObj = new Object();
	  	templateErrorObj.title = "You have the following errors:";
	  	templateErrorObj.errors = errorArray;
	  	
	  	templateArray[0] = templateErrorObj;
	  	
	  	var formErrorsHtml = $(templateSelector).render(templateArray);
	  	
	  	$(placeholderDiv).append(formErrorsHtml);
	}
}
	
function popupDialogWithFormView(url, titleCode, templateSelector, width, height, successFunction) {
	  var dialogDiv = $("<div id='dialog-form'></div>");
	  var jqxhr = $.ajax({
		  url: url,
		  type: 'GET',
		  contentType: 'application/json',
		  dataType: 'json',
		  cache: false,
		  success: function(data, textStatus, jqXHR) {
			
			var formHtml = $(templateSelector).render(data);
			
			dialogDiv.append(formHtml);
			
			var saveButton = jQuery.i18n.prop('dialog.button.save');
			var cancelButton = jQuery.i18n.prop('dialog.button.cancel');
			
			var buttonsOpts = {};
			buttonsOpts[saveButton] = function() {
				$('.multiSelectedItems option').each(function(i) {  
			    	   $(this).attr("selected", "selected");  
			    });
	  				
  				 var form_data = $('#entityform').serialize();
  				 
				 var jqxhr = $.ajax({
					  url: url,
					  type: 'POST',
					  data: form_data,
					  success: successFunction,
					  error: function(jqXHR, textStatus, errorThrown) {
					    handleXhrError(jqXHR, textStatus, errorThrown, "#formErrorsTemplate", "#formerrors");
					  }
				 });
			};
			
			buttonsOpts[cancelButton] = function() {$(this).dialog( "close" );};
			
			dialogDiv.dialog({
			  		title: jQuery.i18n.prop(titleCode),
			  		width: width, 
			  		height: height, 
			  		modal: true,
			  		buttons: buttonsOpts,
			  		close: function() {
			  			// if i dont do this, theres a problem with errors being appended to dialog view second time round
			  			$(this).remove();
					},
			  		open: function (event, ui) {
			  			$('.multiadd').click(function() {  
			  			     return !$('.multiNotSelectedItems option:selected').remove().appendTo('#selectedItems');  
			  			});
			  			
			  			$('.multiremove').click(function() {  
			  				return !$('.multiSelectedItems option:selected').remove().appendTo('#notSelectedItems');  
			  			});
			  			
			  			$('.datepickerfield').datepicker({constrainInput: true, maxDate: 0, dateFormat: 'dd MM yy'});
			  		}
			  	}).dialog('open');
		  }
	  });
}

	
	$("#tabs").tabs({
		"ajaxOptions": {
			type: 'GET',
			dataType: 'json',
			contentType: 'application/json',
			cache: false,
	        error: function( xhr, status, index, anchor) {
	            $(anchor.hash).html("error occured while ajax loading.");
	        },
	        success: function(data, status, xhr) {
	        	var tableHtml = $("#clientSearchTabTemplate").render(data);
				$("#searchtab").html(tableHtml);
				
				$('#client').change(function() {
		        	$('#viewClient').submit();
		    	});
	        }
	    }
	});
	
	var addClientSuccessFunction = function(data, textStatus, jqXHR) {
		  $('#dialog-form').dialog("close");
		  window.location.href = '${rootContext}/portfolio/client/' + data.entityId;
	}
	
	$("#addclient").button().click(function(e) {
		
		var url = '${rootContext}portfolio/client/new';
		var templateSelector = "#clientFormTemplate";
		var width = 600; 
		var height = 350;
		
		popupDialogWithFormView(url, 'dialog.title.add.client', templateSelector, width, height, addClientSuccessFunction);
		
	    e.preventDefault();
	});
	
});
</script>
</head>
<body>

<div id="container">
	<jsp:include page="top-navigation.jsp" />
	
	<c:url value="/portfolio/client/all" var="allClientsUrl" />
	<c:url value="/portfolio/client/add" var="addClientUrl" />
    
	<div style="float:none; clear:both;">
		<div id="spacer" style="line-height: 15px;">&nbsp;</div>
		<div id="content">
			<sec:authorize access="hasAnyRole('PORTFOLIO_MANAGEMENT_SUPER_USER_ROLE', 'CAN_ENROLL_NEW_CLIENT_ROLE')">
			<button id="addclient" style="clear: both;"><spring:message code="link.add.new.client"/></button>
			</sec:authorize>
			<div id="tabs">
				<ul>
					<li><a href="${allClientsUrl}" title="searchtab"><spring:message code="tab.search"/></a></li>
				</ul>
				<div id="searchtab"></div>
			</div>
		</div>
	</div>
</div>

<jsp:include page="view-templates.jsp" />

</body>
</html>