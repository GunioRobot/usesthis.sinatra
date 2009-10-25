$(document).ready(function(){
	if (typeof(interview_slug) != 'undefined'){
		var edit_url = '/' + interview_slug + '/edit/';

		var errors_from_response = function(response){
			var result = $('errors', response).children();
			
			if (result.length < 1){
				return false;
			}
			
			var list = $("<ul class='errors'>");
			
			$(result).each(function(i){
				$(list).append("<li>" + $(result[i]).text() + "</li>")
			});
			
			return list;
		}
		
		var check_wares = function(value){
			var matches = null;
			
			$("p.ware").remove();
			$("form.editor.ware").remove();
			
			while(matches = /\[([^\[\(\)]+)\]\[([a-z0-9\.\-]+)?\]/g.exec(value)){
				if (matches && matches.length > 0){
					var ware_slug = matches[2];
					
					if (typeof(ware_slug) == 'undefined'){
						ware_slug = matches[1].toLowerCase();
					}
					
					$('article.overview').append("<p class='ware' id='" + ware_slug + "'>" + matches[1] + "</p>");
				}
			}
			
			$('p.ware').click(function(){
				var ware = $(this);
				var id = $(ware).attr('id');
				
				if ($("p#" + id + " form").length < 1){
					$.get('/wares/new', {slug: $(ware).attr('id')}, function(data){
						ware.replaceWith(data);
						
						$('form.editor.ware').submit(function(event){
							var form = $(this);
							event.preventDefault();
							
							$.post('/wares/new', $(this).serialize(), function(data){
								if ($('rsp', data).attr('ok') == 1){
									$(form).remove();
									
									$.post('/' + interview_slug + '/relink', function(data){
										$('article.contents').html(data);
									});
								} else {
									$('ul.errors', form).remove();
									$(form).prepend(errors_from_response(data));
								}
							});
						});
					});
				}
			});
		};
	
		check_wares($('article.contents').text());
		
		$('a#publish').click(function(){
			if(!window.confirm('Publish this interview?')) {
				return false;
			}
		
			$.post(edit_url + 'published_at', { published_at: Date() }, function(result){
				$('p.unpublished').replaceWith("<time>" + result + "</time>");
			});
		});
		
		$('h2.person').editable(edit_url + 'person', {
			cssclass: 'editor',
			name: 'person',
			id: ''
		});
	
		$('img.portrait + p').editable(edit_url + 'credits', {
			cssclass: 'editor',
			name: 'credits',
			id: '',
			loadurl: '/' + interview_slug + '/credits'
		});
	
		$('p.summary').editable(edit_url + 'summary', {
			cssclass: 'editor',
			name: 'summary',
			id: ''
		});
	
		$('article.contents').editable(edit_url + 'contents', {
			cssclass: 'editor',
			name: 'contents',
			id: '',
			loadurl: '/' + interview_slug + '/contents',
			type: 'textarea',
			submit: 'OK',
			callback: function(value, settings) {
				check_wares(value);
			}
		});		
	}
});