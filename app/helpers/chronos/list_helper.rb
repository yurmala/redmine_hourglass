module Chronos
  module ListHelper
    def column_header(column, sort_param_name)
      if column.sortable && sort_param_name.present?
        params[:sort] = params.delete sort_param_name
        result = super column
        result.gsub! /(?<!_)sort(?==)/, sort_param_name
        params[sort_param_name] = params.delete :sort
        result.html_safe
      else
        super column
      end
    end

    def grouped_entry_list(entries, query)
      return entry_list entries, &Proc.new unless query.grouped?

      totals_by_group = query.totals_by_group
      count_by_group = query.count_by_group
      grouped_entries(entries, query).each do |group, group_entries|
        yield nil, {
            name: group_name(group, query, group_entries.first),
            totals: transform_totals(extract_group_value(group, totals_by_group)),
            count: extract_group_value(group, count_by_group)
        }
        entry_list group_entries, &Proc.new
      end
    end

    def entry_list(entries)
      entries.each {|entry| yield entry}
    end

    def render_query_totals(query)
      return unless query.totalable_columns.present?
      content_tag 'p', class: 'query-totals' do
        totals_sum(query).each do |column, total|
          concat total_tag(column, total)
        end
      end
    end

    def date_content(entry)
      format_date entry.start
    end

    def start_content(entry)
      format_time entry.start, false
    end

    def stop_content(entry)
      format_time entry.stop, false
    end

    private
    def grouped_entries(entries, query)
      entries.group_by { |entry| query.column_value query.group_by_column, entry }
    end

    def extract_group_value(group, values_by_group)
      values_by_group[group] || values_by_group[group.to_s] || (group.respond_to?(:id) && values_by_group[group.id])
    end

    def transform_totals(totals)
      Hash[totals.map do |column, total|
        [
            column,
            column.name == :hours && total.is_a?(Hash) ? time_booking_total(total) : total
        ]
      end]
    end

    def totals_sum(query)
      if query.grouped?
        query.totals_by_group.each_with_object(Hash.new(0)) do |(_, totals), sum|
          transform_totals(totals).each do |column, total|
            sum[column] += total
          end
        end
      else
        query.totalable_columns.each_with_object(Hash.new(0)) do |column, sum|
          total = query.total_for column
          sum[column] += column.name == :hours && total.is_a?(Hash) ? time_booking_total(total) : total
        end
      end
    end

    def group_name(group, query, first_entry)
      if group.blank? && group != false
        "(#{l(:label_blank_value)})"
      else
        column_content query.group_by_column, first_entry
      end
    end

    def time_booking_total(total)
      total.reduce(0.0) do |sum, total_by_project|
        sum + rounded_total(*total_by_project).to_f.round(2)
      end
    end

    def rounded_total(project_id, total)
      return total unless Chronos::Settings[:round_sums_only, project: project_id]
      Chronos::DateTimeCalculations.in_hours(Chronos::DateTimeCalculations.round_interval total.hours, project: project_id)
    end
  end
end
