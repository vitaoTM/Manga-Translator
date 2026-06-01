module ApplicationHelper
  def status_badge_classes(status)
    case status.to_s
    when "pending"    then "border-stone-600 text-stone-500"
    when "processing" then "border-amber-500 text-amber-400"
    when "completed"  then "border-green-600 text-green-400"
    when "failed"     then "border-red-600 text-red-400"
    else "border-stone-700 text-stone-500"
    end
  end
end
