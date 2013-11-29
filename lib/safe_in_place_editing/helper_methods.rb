########################################################################
# File::    safe_in_place_editing_helper.rb
# (C)::     Hipposoft 2008, 2009
#
# Purpose:: Safe, lockable in-place editing - helper methods.
# ----------------------------------------------------------------------
#           24-Jun-2008 (ADH): Created.
#           22-Oct-2013 (ADH): Incorporated into 'gemified' sources.
########################################################################

module SafeInPlaceEditingHelper

  # == Overview
  #
  # API equivalent of in_place_editor circa 2009, except fixes various bugs
  # (see README.rdoc for the rationale) and:
  #
  # * New option ":lock_var", which is the name of a global variable to be
  #   used in the JS domain to track the lock version at the client side. By
  #   default set to nil, meaning no optimistic locking support. Options
  #   value ":lock_version" MUST be set to the lock version of the object for
  #   which the in-place editor is being created in this case. The variable
  #   is incremented each time the object is successfully updated through the
  #   in-place editor, since the server will have incremented its lock version
  #   so the client must keep in step. If someone else edits the item, the
  #   client and server lock versions will not match and the update will fail,
  #   which is the desired result.
  #
  # * The ":save_text" option is set to "OK" by default, since I detest that
  #   nasty lower case "ok" button that's produced by the JS code otherwise.
  #
  # * The ":cancel_text" option is set to "Cancel" by default to match the
  #   above change.
  #
  # * New option ":is_boolean" indicating a true/false popup should be offered
  #   instead of a text field; if omitted, a text field is assumed. If present
  #   and 'true', additional optional value ":first_value" says whether or not
  #   the pop-up menu should start with True/Yes (if ":first_value"'s value is
  #   itself true), or False/No (if ":first_value"'s value is itself false, or
  #   if the option is omitted).
  #
  # Custom on-failure and on-complete functions are used. To try and reduce
  # the code bulk for each instance of the editor, hard-coded JS function names
  # are used with the support code placed in 'safe_in_place_editing.js'. See
  # there for a reference implementation if intending to write customised
  # equivalents. To override the default names of these functions for any
  # reason, give the names as strings in options properties :on_complete and
  # :on_failure, then make sure appropriate JS functions are actually defined.
  #
  #
  # == Original In Place Editor documentation
  #
  # This is copied from the repository at:
  #
  # * https://github.com/amerine/in_place_editing
  #
  # ...many thanks to those involved.
  #
  # Makes an HTML element specified by the DOM ID +field_id+ become an in-place
  # editor of a property.
  #
  # A form is automatically created and displayed when the user clicks the element,
  # something like this:
  #
  #   <form id="myElement-in-place-edit-form" target="specified url">
  #     <input name="value" text="The content of myElement"/>
  #     <input type="submit" value="ok"/>
  #     <a onclick="javascript to cancel the editing">cancel</a>
  #   </form>
  # 
  # The form is serialized and sent to the server using an AJAX call, the action on
  # the server should process the value and return the updated value in the body of
  # the reponse. The element will automatically be updated with the changed value
  # (as returned from the server).
  #
  # options with (Must be a function) means that you must pass a string like:
  #
  #   function(transport, element) {what_to_do()}
  # 
  # Required +options+ are:
  # <tt>:url</tt>::       Specifies the url where the updated value should
  #                       be sent after the user presses "ok".
  # 
  # Addtional +options+ are:
  # <tt>:rows</tt>::                    Number of rows (more than 1 will use a TEXTAREA)
  # <tt>:cols</tt>::                    Number of characters the text input should span (works for both INPUT and TEXTAREA)
  # <tt>:size</tt>::                    Synonym for :cols when using a single line text input.
  # <tt>:cancel_text</tt>::             The text on the cancel link. (default: "cancel")
  # <tt>:save_text</tt>::               The text on the save link. (default: "ok")
  # <tt>:loading_text</tt>::            The text to display while the data is being loaded from the server (default: "Loading...")
  # <tt>:saving_text</tt>::             The text to display when submitting to the server (default: "Saving...")
  # <tt>:external_control</tt>::        The id of an external control used to enter edit mode.
  # <tt>:load_text_url</tt>::           URL where initial value of editor (content) is retrieved.
  # <tt>:options</tt>::                 Pass through options to the AJAX call (see prototype's Ajax.Updater)
  # <tt>:with</tt>::                    JavaScript snippet that should return what is to be sent
  #                                     in the AJAX call, +form+ is an implicit parameter
  # <tt>:script</tt>::                  Instructs the in-place editor to evaluate the remote JavaScript response (default: false)
  # <tt>:click_to_edit_text</tt>::      The text shown during mouseover the editable text (default: "Click to edit")
  # <tt>:on_complete</tt>::             (Must be a function)Code run if update successful with server. Also if user cancels the form (see https://prototype.lighthouseapp.com/projects/8887/tickets/243).
  # <tt>:on_failure</tt>::              (Must be a function)Code run if update failed with server
  #
  def safe_in_place_editor( field_id, options = {} )

    # Set up some default values

    options[ :with ] ||= "Form.serialize(form).replace(/\\+/g,'%20')"

    if protect_against_forgery?
      options[ :with ] += " + '&authenticity_token=' + encodeURIComponent('#{ form_authenticity_token }')"
    end

    options[ :on_complete ] ||= 'safeInPlaceEditorOnComplete'
    options[ :on_failure  ] ||= 'safeInPlaceEditorOnFailure'
    options[ :save_text   ] ||= 'OK'
    options[ :cancel_text ] ||= 'Cancel'

    # Preliminary script data

    if ( options.include?( :lock_var ) )
      function = "window['#{ options[ :lock_var ] }']=#{ options[ :lock_version ] };"
    else
      function = ''
    end

    function_name = options[ :is_boolean ] ? 'InPlaceCollectionEditor' : 'InPlaceEditor'

    function << "new Ajax.#{ function_name }("
    function << "'#{ field_id }', "
    function << "'#{ url_for( options[ :url ] ) }'"

    # Map Rails in-place editor options to JS in-place editor options - see:
    #
    #   http://github.com/madrobby/scriptaculous/wikis/ajax-inplaceeditor

    js_options = {}

    js_options[ 'rows'                ] =   options[ :rows    ] if options[ :rows    ]
    js_options[ 'cols'                ] =   options[ :cols    ] if options[ :cols    ]
    js_options[ 'size'                ] =   options[ :size    ] if options[ :size    ]
    js_options[ 'ajaxOptions'         ] =   options[ :options ] if options[ :options ]
    js_options[ 'htmlResponse'        ] = ! options[ :script  ] if options[ :script  ]

    js_options[ 'cancelText'          ] = %('#{ options[ :cancel_text           ] }') if options[ :cancel_text           ]
    js_options[ 'okText'              ] = %('#{ options[ :save_text             ] }') if options[ :save_text             ]
    js_options[ 'loadingText'         ] = %('#{ options[ :loading_text          ] }') if options[ :loading_text          ]
    js_options[ 'savingText'          ] = %('#{ options[ :saving_text           ] }') if options[ :saving_text           ]
    js_options[ 'clickToEditText'     ] = %('#{ options[ :click_to_edit_text    ] }') if options[ :click_to_edit_text    ]
    js_options[ 'textBetweenControls' ] = %('#{ options[ :text_between_controls ] }') if options[ :text_between_controls ]

    js_options[ 'externalControl'     ] = "'#{          options[ :external_control ]   }'" if options[ :external_control ]
    js_options[ 'loadTextURL'         ] = "'#{ url_for( options[ :load_text_url    ] ) }'" if options[ :load_text_url    ]

    js_options[ 'callback'            ] = "function(form) { return #{ options[ :with ] }; }" if options[ :with ]

    if options[ :is_boolean ]
      if options[ :start_value ]
        js_options[ 'collection' ] = "[['true','Yes'],['false','No']]"
      else
        js_options[ 'collection' ] = "[['false','No'],['true','Yes']]"
      end
    end

    # Set up the custom on-failure and on-complete handlers

    js_options[ 'onFailure' ] = "#{ options[ :on_failure ] }"

    if ( options.include?( :lock_var ) )
      js_options['onComplete'] = "function(transport, element) {#{ options[ :on_complete ] }(transport,element,'#{ options[ :lock_var ] }');}"
    else
      js_options['onComplete'] = "#{ options[ :on_complete ] }"
    end

    # Assemble the content

    function << ( ', ' + options_for_javascript( js_options ) ) unless js_options.empty?
    function << ')'

    return javascript_tag( function )
  end

  # Close API equivalent of in_place_editor_field, except fixes various bugs
  # (see the README for rationale). Allows either an object name in the first
  # parameter (e.g. ":foo", in which case instance variable "@foo" must point
  # to the object instance of interest) or an object instance (to save messing
  # around with magic instance variables, but obtains the object name from
  # "class.name.underscore", so may not be appropriate for unusual object
  # classes). Anyway, clearer error reporting and the ability to pass in an
  # object reference directly may help avoid a common error experienced with
  # the InPlaceEditing plug-in code, as described here at the time of writing:
  #
  # http://oldwiki.rubyonrails.org/rails/pages/InPlaceEditing
  #
  # Includes the following options:
  #
  # * :lock_var is the name of the variable used for optimistic locking, by
  #   default set to a row-unique value. The assumption is that this same
  #   variable gets used throughout the row so that multiple edits on that
  #   row all cause the same variable to be incremented. If your back-end
  #   update function has side effects that might invalidate the value shown
  #   in another column on that row - which would be pretty strange! - you'd
  #   need to override the lock variable name with something that's unique to
  #   both the row and the column. When using a lock variable, additional
  #   option ":lock_version" is always set internally to the lock version of
  #   the object for which the field is being built and cannot be overridden.
  #
  # * :with is extended to include a "lock_version" parameter in the query
  #   string so that the client side's idea of the current object's lock
  #   version may be communicated to the server's attribute update action.
  #   This is done internally; there is no need to set the option yourself.
  #
  # The editor options also support "is_boolean", which overrides the default
  # setting of whether or not the column value is considered to be a string
  # or a boolean quantity. This is provided just-in-case, with no current
  # known cases where the automatic detection isn't sufficient.
  #
  # The Prototype library getText function must be patched as described in
  # the README rationale; "application.js" is a good place to do this.
  #
  # Note an optional fifth parameter which if 'true' will prevent HTML
  # escaping of the value for values which are really meant to contain HTML
  # code. Be very, very careful with this.
  #
  def safe_in_place_editor_field( object, method, tag_options = {}, editor_options = {}, no_escape = false )

    # Allow a symbol or object instance to be passed. Since the symbol use
    # case involves accessing a 'magic' related instance variable name and
    # since there are lots of examples via Google of this confusing people,
    # raise a helpful error message if the relevant variable is missing.

    if ( object.instance_of?( Symbol ) )
      object_name = object
      var_name = "@#{ object_name }"
      if ( instance_variable_defined?( var_name ) )
        object = instance_variable_get( var_name )
      else
        raise( 'If passing \':foo\' to in_place_editor_field, \'@foo\' must refer to the object for which the field is being built' )
      end
    else
      object_name = object.class.name.underscore
    end

    # Pass the lock version in for optimistic locking support, should the
    # object support it. The update callback function must manually compare
    # the params[ :lock_version ] value against the lock_version.to_s()
    # value of the object that's being updated.

    if ( object.respond_to?( :lock_version ) )
      var = "#{ object_name }_#{ object.id }_safeInPlaceEditorLockVersion"

      editor_options[ :lock_version ]   = object.lock_version.to_s
      editor_options[ :lock_var     ] ||= var
      editor_options[ :with         ] ||= "Form.serialize(form).replace(/\\+/g,'%20')"
      editor_options[ :with         ]  += " + '&lock_version=' + #{ var }"
    end

    # Escape the value unless told not to and construct the complete in-place
    # editor assembly. Check for boolean values too, allowing caller-override.

    column_value = object.send( method )

    is_boolean = ( editor_options[ :is_boolean ] || ( column_value.is_a? TrueClass ) || ( column_value.is_a? FalseClass ) )

    if ( is_boolean )
      editor_options[ :start_value ] = !! column_value
      column_value = column_value ? 'Yes' : 'No'
    else
      column_value = ERB::Util::html_escape( column_value ) unless ( no_escape )
    end

    tag_options = {
      :id    => "#{ object_name }_#{ method }_#{ object.id }_in_place_editor",
      :class => "in_place_editor_field"
    }.merge!( tag_options )

    editor_options[ :url ] ||= url_for( {
      :action => "set_#{ object_name }_#{ method }",
      :id     => object.id
    } )

    # Update the boolean value flag, unless the caller had already set one.

    editor_options[ :is_boolean ] = is_boolean unless editor_options.has_key?( :is_boolean )

    return content_tag( :span, column_value.html_safe, tag_options ) +
           safe_in_place_editor( tag_options[ :id ], editor_options )
  end
end
