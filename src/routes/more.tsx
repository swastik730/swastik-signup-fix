import { createFileRoute, Link } from "@tanstack/react-router";
import {

  Crown,
  Download,
  HelpCircle,
  Info,
  LayoutGrid,
  Lightbulb,
  Share2,
  Sparkles,
} from "lucide-react";
import { AppShell } from "@/components/AppShell";
import { PageHero } from "@/components/PageHero";
import heroMore from "@/assets/hero-more.webp";
import tileNcert from "@/assets/tiles/ncert.webp";
import tileAnalysis from "@/assets/tiles/analysis.webp";
import tileCalendar from "@/assets/tiles/calendar.webp";
import tileTrophy from "@/assets/tiles/trophy.webp";
import tileLeaderboard from "@/assets/tiles/leaderboard.webp";

export const Route = createFileRoute("/more")({
  head: () => ({
    meta: [
      { title: "More | BoardBuddy" },
      {
        name: "description",
        content:
          "More BoardBuddy tools: study calendar, achievements, analysis, downloads, study tips, help and support for Class 10 students.",
      },
      { property: "og:title", content: "More | BoardBuddy" },
      { property: "og:description", content: "Calendar, achievements, analysis, downloads and support in one place." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: MorePage,
});

const TOOLS = [
  {
    to: "/ncert",
    img: tileNcert,
    label: "NCERT Solutions",
    hint: "Chapter-wise textbook answers",
    panel: "hero-panel-blue",
  },
  {
    to: "/analysis",
    img: tileAnalysis,
    label: "My Analysis",
    hint: "Detailed performance insights",
    panel: "amber-panel",
  },
  {
    to: "/calendar",
    img: tileCalendar,
    label: "Study Calendar",
    hint: "Plan your daily study",
    panel: "test-panel",
  },
  {
    to: "/achievements",
    img: tileTrophy,
    label: "Achievements",
    hint: "Badges you have unlocked",
    panel: "bookmark-panel",
  },
  {
    to: "/leaderboard",
    img: tileLeaderboard,
    label: "Leaderboard",
    hint: "Compete with other students",
    panel: "purple-panel",
  },
] as const;

const RESOURCES = [
  { icon: Download, label: "Downloads", hint: "Saved notes & offline content", chip: "bg-primary/15 text-primary" },
  { icon: Lightbulb, label: "Study Tips", hint: "Smart board exam strategies", chip: "bg-hero-amber/20 text-hero-amber" },
  { icon: Sparkles, label: "Exam Guide", hint: "Paper pattern & marking scheme", chip: "bg-hero-purple/18 text-hero-purple" },
  { icon: Share2, label: "Invite Friends", hint: "Share BoardBuddy with classmates", chip: "bg-hero-green/18 text-hero-green" },
  { icon: HelpCircle, label: "Help & Support", hint: "FAQs and contact", chip: "bg-achievement-soft text-achievement" },
  { icon: Info, label: "About Us", hint: "Version 1.0.0", chip: "bg-destructive-soft text-destructive" },
] as const;

function MorePage() {


  return (
    <AppShell title="More">
      <PageHero
        eyebrow="More"
        eyebrowIcon={<LayoutGrid className="h-3.5 w-3.5" />}
        title="Everything else"
        titleAccent="to power your prep"
        description="Solutions, planner, badges and support — all your extra study tools in one colourful place."
        image={heroMore}
        imageAlt="Colourful 3D study toolbox illustration"
        tint="purple"
      />

      <div className="surface mb-5 flex items-center gap-4 p-5">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-success-soft text-success">
          <Crown className="h-6 w-6" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-base font-extrabold">Everything is free</p>
          <p className="text-xs text-muted-foreground">
            All tests, analytics and solutions unlocked — no subscription, ever.
          </p>
        </div>
      </div>


      <h2 className="mb-3 flex items-center gap-2 text-sm font-bold">
        <span className="h-4 w-1 rounded-full bg-hero-purple" />
        Study tools
      </h2>
      <div className="mb-6 grid grid-cols-2 gap-3">
        {TOOLS.map(({ to, img, label, hint, panel }) => (
          <Link
            key={to}
            to={to}
            className={`${panel} flex flex-col p-4 transition-transform active:scale-[0.98]`}
          >
            <img
              src={img}
              alt={label}
              width={640}
              height={640}
              loading="lazy"
              decoding="async"
              className="h-14 w-14 select-none object-contain drop-shadow"
            />
            <p className="mt-3 text-sm font-bold">{label}</p>
            <p className="text-[11px] leading-snug text-muted-foreground">{hint}</p>
          </Link>
        ))}
      </div>

      <h2 className="mb-3 flex items-center gap-2 text-sm font-bold">
        <span className="h-4 w-1 rounded-full bg-hero-purple" />
        Resources
      </h2>
      <div className="surface divide-y divide-border">
        {RESOURCES.map(({ icon: Icon, label, hint, chip }) => (
          <div key={label} className="flex items-center gap-3 px-4 py-3.5">
            <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-2xl ${chip}`}>
              <Icon className="h-5 w-5" />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-bold">{label}</p>
              <p className="truncate text-[11px] text-muted-foreground">{hint}</p>
            </div>
            <span className="shrink-0 rounded-full bg-hero-purple/12 px-2 py-0.5 text-[10px] font-bold text-hero-purple">
              Soon
            </span>
          </div>
        ))}
      </div>

      <p className="py-5 text-center text-xs text-muted-foreground">
        BoardBuddy · Your Smart Board Exam Partner
      </p>
    </AppShell>
  );
}
