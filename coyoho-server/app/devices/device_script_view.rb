=begin

This file is part of the CoYoHo Control Your Home System.

Copyright 2011-2012 Dirk Grappendorf, www.grappendorf.net

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end

# TODO: Currently there is a bug with CodeMirror. If CodeMirror is used as a form field, the
# previous CodeMirror is not removed from the form, every second time when the item_data_source
# is changed.
# So currently the CodeMirror field is added as a seperate component and the value of the script
# field is transfered manually.

require 'devices/device_script'

class DeviceScriptView < View

	include Securable
	
	inject :device_script_manager

	register_as :device_script_view, scope: :session

	TABLE_COLUMNS = [:enabled, :name, :description, :created_at, :updated_at, :actions]
	FORM_FIELDS = [:enabled, :name, :description]

	def initialize
		super T('view.device_scripts.name'), T('view.device_scripts.title'), 'icons/48/execute.png', 3
	end 

	def create_content
 
		@items = Rubydin::DataMapperContainer.new DeviceScript

		gui = Rubydin::Builder.new
		content = gui.VerticalLayout do
			@table = gui.Table '', @items do |t|
				t.selectable = true
				t.immediate = true
				t.full_size
				t.generated_column :enabled, &Rubydin::Table.boolean_image_column
				t.generated_column :actions, do |source, item_id, column_id|
					create_action_buttons item_id
				end
				t.visible_columns TABLE_COLUMNS
				t.column_expand_ratio :description, 1.0
				t.column_header :enabled, T('domain.attributes.DeviceScript.enabled')
				t.column_header :name, T('domain.attributes.DeviceScript.name')
				t.column_header :description, T('domain.attributes.DeviceScript.description')
				t.column_header :created_at, T('domain.attributes._.created_at')
				t.column_header :updated_at, T('domain.attributes._.updated_at')
				t.column_header :actions, ''
				t.when_selection_changed {|e| edit e.property.value}
			end
			@form = gui.Form
			@form.form_field_factory = Rubydin::DataMapperFormFieldFactory.new
			@script_editor = gui.CodeMirror nil,
				Rubydin::CodeMirror::MODE_RUBY, Rubydin::CodeMirror::THEME_MONOKAI
			@script_editor.width = '100%'
			gui.HorizontalLayout do |h|
				h.margin = true, false, false, false
				h.spacing = true
				gui.Button T('save') do |b|
					b.setIcon Rubydin::ThemeResource.new 'icons/16/ok.png'
					b.when_clicked {save}
				end
				gui.Button T('discard') do |b|
					b.setIcon Rubydin::ThemeResource.new 'icons/16/undo.png'
					b.when_clicked {discard}
				end
				gui.Button T('create') do |b|
					b.setIcon Rubydin::ThemeResource.new 'icons/16/new.png'
					b.when_clicked {create}
				end
				gui.Button T('delete') do |b|
					b.setIcon Rubydin::ThemeResource.new 'icons/16/trashcan.png'
					b.when_clicked {delete}
				end
			end
		end

		create

		content
	end

	def create_action_buttons item_id
		layout = Rubydin::HorizontalLayout.new
		button = Rubydin::Button.new
		button.icon = Rubydin::ThemeResource.new 'icons/16/trashcan.png'
		button.when_clicked {delete item_id}
		layout.add button
		layout
	end

	def create
		item = Rubydin::DataMapperItem.new DeviceScript.new
		@form.item_data_source = item, FORM_FIELDS
		@script_editor.value = ''
		@table.value = nil
		@form.focus
	end

	def edit item_id
		if item_id
			item = @items.item(item_id).item
			@form.item_data_source = Rubydin::DataMapperItem.new(item), FORM_FIELDS
			@script_editor.value = item.script
			@form.focus
		else
			create
		end
	end

	def save
		if @form.commit!
			data = @form.item_data_source.data
			data.script = @script_editor.value
			device_script_manager.update_script data 
			@table.container_data_source = @items
			@table.visible_columns TABLE_COLUMNS
			@table.value = data.id
			@form.focus
			show_notification 'Device script saved'
		end
	end

	def discard
		@form.discard
		data = @form.item_data_source.data
		@script_editor.value = data.script
		@form.focus
	end

	def delete id = nil
		id = @form.item_data_source.data.id unless id
		if id
			data = @items.item(id).item
			Rubydin::ConfirmDialog::show window, 'Confirm deletion',
			"Do you really want to<br />delete device script <b>#{data.name}</b>?",
			'Yes', 'No' do |dialog|
				if dialog.confirmed?
					data.destroy
					@table.container_data_source = @items
					@table.visible_columns TABLE_COLUMNS
					create
				end
			end
		end
	end

end