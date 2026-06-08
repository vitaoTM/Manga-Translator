module ApplicationHelper
  def status_badge_classes(status)
    case status.to_s
    when "pending"    then "bg-zinc-800 text-zinc-400"
    when "processing" then "bg-violet-900/50 text-violet-300 border border-violet-500/30"
    when "completed"  then "bg-emerald-900/50 text-emerald-300 border border-emerald-500/30"
    when "failed"     then "bg-rose-900/50 text-rose-300 border border-rose-500/30"
    else "bg-zinc-800 text-zinc-500"
    end
  end
end
