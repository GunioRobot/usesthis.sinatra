$(document).ready(function(){
	if (typeof(interview_slug) != 'undefined'){
		var edit_url = '/' + interview_slug + '/edit/';

		var check_wares = function(value){
			var matches = null;
			
			if ($('ul#wares').length < 1){
				$('article.overview').append('<ul id="wares"></ul>');
			} else {
				$('ul#wares').empty();
			}
			
			while(matches = /\[([^\[\(\)]+)\]\[([a-z0-9\.\-]+)?\]/g.exec(value)){
				if (matches && matches.length > 0){
					var ware_slug = matches[2];
					
					if (typeof(ware_slug) == 'undefined'){
						ware_slug = matches[1].toLowerCase();
					}
					
					$('ul#wares').append('<li id="' + ware_slug + '"><a href="#">' + matches[1] + '</a></li>');
				}
			}
		};
		
		check_wares($('article.contents').text());
		
		$('ul#wares li a').live('click', function(event){
			var ware = $(this).parent();
			event.preventDefault();
			
			if ($(ware).children('form.editor.ware').length < 1){
				$.get('/wares/new', {slug: $(ware).attr('id')}, function(data){
					ware.append(data);
				});
			} else {
				
				if($('form.editor.ware', ware).is(':hidden')){
					$('form.editor.ware', ware).show();
				} else {
					$('form.editor.ware', ware).hide();
				}
			}
		});
		
		$('form.editor.ware').live('submit', function(event){
			var form = $(this);
			event.preventDefault();
			
			$.ajax({
				type: 'POST',
				url: '/wares/new',
				data: $(this).serialize(),
				dataType: 'json',
				complete: function(request, status){
					if (request.status == 200){
						$(form).remove();
						$.get('/' + interview_slug + '/relink', function(data){
							$('article.contents').html(data);
							check_wares(data);
						});
					} else {
						$('ul.errors', form).remove();
						$(form).prepend(request.responseText);
					}
				}
			});
			
		});
		
		$('a#publish').click(function(){
			if(!window.confirm('Publish this interview?')) {
				return false;
			}
		
			$.post(edit_url + 'published_at', { published_at: Date() }, function(result){
				$('p.unpublished').replaceWith('<time>' + result + '</time>');
			});
		});
		
		$('h2.person').editable(edit_url + 'person', {
			cssclass: 'editor interview',
			name: 'person',
			id: '',
			onblur: 'ignore'
		});
	
		$('img.portrait + p').editable(edit_url + 'credits', {
			cssclass: 'editor interview',
			name: 'credits',
			id: '',
			onblur: 'ignore',
			loadurl: '/' + interview_slug + '/credits'
		});
	
		$('p.summary').editable(edit_url + 'summary', {
			cssclass: 'editor interview',
			name: 'summary',
			id: '',
			onblur: 'ignore'
		});
	
		$('article.contents').editable(edit_url + 'contents', {
			cssclass: 'editor interview',
			name: 'contents',
			id: '',
			onblur: 'ignore',
			loadurl: '/' + interview_slug + '/contents',
			type: 'textarea',
			submit: 'OK',
			rows: '20',
			callback: function(value, settings) {
				check_wares(value);
			}
		});
	}
});