# frozen_string_literal: true

module RedmineRemainingTimeFilter
  module IssueQueryPatch
    def available_filters
      super
      @available_filters ||= {}

      unless @available_filters.key?("remaining_time")
        add_available_filter(
          "remaining_time",
          type: :float,
          name: "Remaining time"
        )
      end

      @available_filters
    end

    def sql_for_remaining_time_field(_field, operator, values)
      remaining_expr = <<~SQL.squish
        (
          COALESCE(#{Issue.table_name}.estimated_hours, 0) -
          COALESCE(
            (SELECT SUM(te.hours)
             FROM #{TimeEntry.table_name} te
             WHERE te.issue_id = #{Issue.table_name}.id),
            0
          )
        )
      SQL

      q  = ActiveRecord::Base.connection
      v1 = values[0].to_f
      v2 = values[1].to_f

      case operator
      when "="  then "#{remaining_expr} = #{q.quote(v1)}"
      when ">"  then "#{remaining_expr} > #{q.quote(v1)}"
      when "<"  then "#{remaining_expr} < #{q.quote(v1)}"
      when ">=" then "#{remaining_expr} >= #{q.quote(v1)}"
      when "<=" then "#{remaining_expr} <= #{q.quote(v1)}"
      when "><"
        a, b = [v1, v2].minmax
        "#{remaining_expr} BETWEEN #{q.quote(a)} AND #{q.quote(b)}"
      else
        "1=1"
      end
    end
  end
end

