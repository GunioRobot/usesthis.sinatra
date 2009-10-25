$(document).ready(function(){
	if (typeof(interview_slug) != 'undefined'){
		var edit_url = '/' + interview_slug + '/edit/';

		var wares_editor = function(){
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
		};		
		
		check_wares($('article.contents').text());
		
		$('p.ware').live('click', function(){
			var ware = $(this);
			var id = $(ware).attr('id');

			if ($("p#" + id + " form").length < 1){
				$.get('/wares/new', {slug: $(ware).attr('id')}, function(data){
					ware.replaceWith(data);
				});
			}
		});
		
		$('form.editor.ware').live('submit', function(event){
			var form = $(this);
			event.preventDefault();
			
			$.ajax({
				type: 'POST',
				url: '/wares/new',
				data: $(this).serialize(),
				complete: function(request, status){
					if (request.status == 201){
						$(form).remove();
						$.get('/' + interview_slug + '/relink', function(data){
							$('article.contents').html(data);
						});
						
					} else {
						$(form).replaceWith($(request.responseText));
					}
				}
			});
			
		});
		
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