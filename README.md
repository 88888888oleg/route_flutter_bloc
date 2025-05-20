Avoid unnecessary rebuilds and side-effects when pages are hidden in the navigation stack.  
React only when needed. Improve performance without changing your app’s architecture.  
route_flutter_bloc is a collection of enhanced versions of standard flutter_bloc widgets like BlocBuilder, BlocListener, and others.  
These widgets are navigation-aware — they know when your page is on screen or hidden inside the Navigator stack, and behave accordingly.

✅ Why use it?

In a typical Flutter app using flutter_bloc, your BlocBuilder or BlocListener widgets always work, even when the page is not visible.  
This can lead to:  
• 🔁 Unnecessary rebuilds that waste performance  
• ⚠️ Side-effects from BlocListener firing at the wrong time  
• 🐌 Slower UI if you’re triggering manual UI updates through BlocListener

💡 How this package solves it

This package upgrades the default behavior. All widgets behave the same as in flutter_bloc, except when the screen is hidden.

Here’s what you get:  
• ✅ When the page is visible — everything works as usual.  
• 💤 When the page is in the navigator stack but not on screen — widgets do nothing.  
• 🔄 When the page becomes visible again — widgets can:  
• Rebuild (RouteBlocBuilder)  
• React with side-effects (RouteBlocListener)  
• But only if the state changed while the page was hidden.

By default, these widgets stay quiet when coming back to the screen.  
But if you want them to react on resume, just enable a flag:  
• rebuildOnResume: true for RouteBlocBuilder  
• triggerOnResumed: true for RouteBlocListener

This ensures the widget reacts once with the latest changed state — only if something really changed.

And yes — even if the final state equals the original, widgets still react if there was a transition.  
For example:  
• loaded → loading → loaded → Triggers ✅  
• loaded → loaded → No trigger ❌

This keeps performance high and avoids wasting rebuilds.

🧠 Want the original behavior?

No problem.  
You can make any widget behave like its flutter_bloc counterpart by enabling:  
• forceClassicBuilder: true  
• forceClassicListener: true  
• forceClassicSelector: true

This disables the route-aware logic and makes widgets work always, regardless of screen visibility.

## 🧠 Widget Behavior Based on State and Visibility

| Page Visible? | State Changed? | Example Transitions           | Flag: rebuildOnResume / triggerOnResumed | Will Trigger? | Explanation                                                        |
|---------------|----------------|-------------------------------|-------------------------------------------|----------------|--------------------------------------------------------------------|
| ✅ Yes        | ✅ Yes          | loaded → loading → loaded     | irrelevant                                | ✅ Yes         | The page is visible, all changes trigger the widget as expected.  |
| ✅ Yes        | ❌ No           | loaded → loaded               | irrelevant                                | ❌ No          | No actual state change – widget does not trigger (optimization).  |
| ❌ No         | ✅ Yes          | loaded → loading → loaded     | ❌ false                                   | ❌ No          | State changed, but flag is off – widget stays silent.             |
| ❌ No         | ✅ Yes          | loaded → loading → loaded     | ✅ true                                    | ✅ Yes (once)  | State changed while hidden – widget triggers once on resume.      |

