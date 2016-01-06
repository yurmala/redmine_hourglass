class Chronos::RedmineHooks < Redmine::Hook::ViewListener
  def view_issues_show_description_bottom(context = {})
    load_chronos_helper context[:hook_caller]
    context[:controller].render_to_string partial: 'hooks/issue_actions'
  end

  def view_issues_context_menu_start(context = {})
    load_chronos_helper context[:hook_caller]
    context[:controller].render_to_string partial: 'hooks/issue_actions'
  end

  def view_layouts_base_html_head(context = {})
    load_chronos_helper self
    context[:hook_caller].content_for :header_tags, javascript_include_tag('global', plugin: Chronos.plugin_name)
    context[:hook_caller].content_for :header_tags, stylesheet_link_tag('global', plugin: Chronos.plugin_name)
  end

  def view_layouts_base_content(context = {})
    load_chronos_helper context[:hook_caller]
    context[:controller].render_to_string partial: 'hooks/account_menu_link'
  end

  def self.load!
    #load hook specific stuff
  end

  private

  def load_chronos_helper(extendable)
    extendable.class.send :include, Chronos::ApplicationHelper
  end
end
