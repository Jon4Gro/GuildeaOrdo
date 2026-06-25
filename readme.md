# **Guildera Ordo (v1.0)**

Guildera Ordo is an all-in-one Guild Management addon natively engineered for **World of Warcraft: Wrath of the Lich King (Patch 3.3.5a)**. Built on the classic frame API (CreateFrame, GuildRosterInfo, SetWhoToUI, FauxScrollFrame, EasyMenu context menus, etc.), it delivers high-volume guild ops without tainting the default UI.  
Features include deep event logging, alt-character mapping, channel-bound macros, batch rate-limited promote/kick, smart auto-invite systems with level gating, a minimap button with rotation and distance controls, 0-minute infinite timers, and a powerful account-wide Blacklist for both Auto Guild and Auto Group Invites.

## **⚠️ Known Bug & The Guildera Ordo Solution**

* **Blizzard GuildFrame Offline Bug**: With the addon loaded, the stock GuildRosterFrame can get stuck defaulting to "Show Offline Members" after any sort of click.  
* **Roster Tab to the Rescue**: Our custom ROSTER view (powered by collectRosterRows, live rosterPlayerSearch / rosterNoteSearch / rosterOfflineDaysSearch filters, and ROSTER\_COLS layout) completely replaces the need to fight the default frame. Right-click context menus (showRosterContextMenu) give instant whitelist, promote, demote, whisper, and group invite actions.

## **What's New in Guildera Ordo v1.0**

* **Modular UI & Codebase Refactoring**: The UI monolithic file has been split into targeted files (UI\_Main.lua, UI\_Log.lua, UI\_Roster.lua, UI\_Alts.lua, UI\_Macros.lua, UI\_Ranks.lua, UI\_Settings.lua, UI\_Blacklist.lua) for improved maintenance and readability.  
* **SavedVariables Migration**: The Auto-Invite settings (enabled, phrase, groupinv, minLvl, etc.) have been safely migrated from the account-wide GildeaOrdoDB to the character-specific GildeaOrdoCharDB.  
* **Blacklist Enhancements**: Added a "Purge List" button with double-confirmation to wipe all entries, and introduced a dynamic search filter for the Blacklist window.  
* **Auto Group Invite Polish**: Removed the "Permanent" checkbox; you can now natively set the group invite to permanent by entering 0 in the minutes field.

## **What's Past with GManager v1.5**

* **BlacklistDetail Window**: The main Blacklist window height was reduced, and the "Remove" button was moved into a new **BlacklistDetail** panel shown below the list:  
  * Displays the selected player's name.  
  * Features a remove button on the right.  
  * Includes a local notes editbox with a 200 character limit and multiline support.  
* **Ban Member Right-Click Option** (Roster context menu):  
  * Requires confirmation.  
  * Kicks the member and adds them to the blacklist.  
  * Automatically writes an officer note in the format: OfficerName MMM DD YYYY: banned.  
* **Auto Ban on Leaving** (Settings checkbox above Blacklist button):  
  * Automatically adds players who leave the guild to the blacklist.  
  * Note format: MMM DD YYYY: Quit Guild.  
* **Share Blacklist to Officer Chat**:  
  * New button above "Auto Ban on Leaving".  
  * Shares all blacklisted members and their notes via in-game Officer chat.  
  * The addon listens on Officer chat and automatically adds or updates received entries with notes.  
* **Roster View Enhancement**:  
  * Matching criteria counter (from Ranks view) is now also shown below the right header in Roster view, reflecting current displayed members.  
* **Various UI Polish**:  
  * Blacklist and detail editboxes are limited to 200 characters.  
  * Improved multiline support and sizing for Autoresponse and Local Notes.  
  * Height adjustments across Blacklist-related windows.

## 

## **Core Features**

### **🛡️ Whitelisting**

* Protected members (green \[W\] tag in roster rows) are skipped by every mass operation (ProcessBatch, mass kick, mass promote).  
* Toggle via right-click context menu or the whitelist API in Core.lua.

### 

### **🛑 Blacklist**

* Account-wide list that blocks players from both Auto Guild Invite and Auto Group Invite.  
* Add/remove via the Settings → Blacklist... window (docked to the right).  
* Optional autoresponse sent to blacklisted players.  
* Slash command support: /go bladd and /go bl.  
* Works even if auto-invite is enabled.

### 

### **🥾 Mass Kick List**

* Filter the roster (name/note/offline-days), preview the list, then execute in safe configurable batches (GildeaOrdoDB.batchSize).  
* Includes double confirmation and whitelist bypass.  
* All kicks go through GuildUninvite with post-action RequestRosterAfterAction delay.

### 

### **🎖️ Mass Promote List (Ranks Tab)**

* Select a baseline rank in the Ranks view, set min-days-in-guild \+ max-offline filters, preview candidates (parsed from officer note date tags like \[Jun 09 2026\]), then batch promote.  
* Respects whitelist.  
* Dynamic GuildControlGetRankName / GuildControlGetNumRanks integration.

### 

### **✉️ Auto Guild & Party Invites**

* **Guild Whisper Triggers**: Custom phrase (supports multiple words separated by \-).  
* When matched, triggers a silent /who level check → minLvl gate → invite or replyLow.  
* Configurable replyOn / replyOff messages.  
* Fully protected by the new Blacklist system.  
* **Party / Group Auto-Invites**: Toggle via Settings.  
* Minutes field supports **0 for infinite** (no auto-stop timer) natively.  
* Same trigger phrase support and is blocked by the blacklist.  
* **Rate & Safety**: Uses delayCall scheduler, exact-name /who quoting, and focus guards on all EditBoxes.

### 

### **📜 Event Log**

* Up to 15,000 entries per guild.  
* Types include: JOIN, LEAVE, PROMOTE, DEMOTE, NOTE, ONOTE, SEEN.  
* Full text search, type filters, and line numbers.  
* fmtDateLong and fmtSince helpers give human-readable timestamps and "X days ago" strings.  
* Color-coded with the TYPE\_COLOR table.

### 

### **🔗 Alts Mapping**

* SetAlt / GetMainOf / GetAltsOf are stored per-guild in GildeaOrdoDB.guilds\[key\].alts.  
* Displayed in both Roster rows (\<M\> / (alt)) and the dedicated Alts tab \+ Member Detail panel (Roster.lua).

### **💬 Account-Wide Macros \+ Spam**

* Save any text bound to a channel (1-9, GUILD, OFFICER, SAY, PARTY, RAID, YELL).  
* Send instantly or add to rotation.  
* spamUpdater OnUpdate ticker respects spamInterval (minutes) plus an optional **total time limit** (0 \= infinite).  
* Spam checkboxes per macro row with live \[SPAM\] tag.

## 

## **Interface Tabs (6 total)**

All built with plain Wrath frame API. Major buttons/headers use classic |cFFFFCC00 yellowish gold.

1. **Log Tab** – Search, type filter checkboxes, numbered lines, and a clear button. Right side filter panel.  
2. **Roster Tab** – Show offline toggle, player/note search, offline-days threshold, group-alts checkbox, mass-kick button, and ONote-empty button. Sortable columns and a rich right-click menu.  
3. **Alts Tab** – Simple list of alt → main mappings with Set / Unset inputs.  
4. **Macros Tab** – Channel buttons, message EditBox \+ Save, spam interval \+ total limit (0=inf) \+ enable checkbox. Includes per-row action buttons.  
5. **Ranks Tab** – Baseline rank selector, min-days / max-offline filters, candidate preview, and mass-promote button.  
6. **Settings Tab**:  
   * Batch size, Open/Close with GuildFrame options.  
   * Minimap Button Controls (Show \+ Rotation/Distance).  
   * **Auto Guild Invite** controls (phrase, replies, min level, reply low).  
   * **Auto Group Invite** (phrase, minutes 0=inf).  
   * **Blacklist...** button (bottom-right) — opens the account-wide blacklist manager docked to the right of the main window.

Access with /go or /GuilderaOrdo. The main frame (GildeaOrdoMainFrame) is movable, clamped, and high-strata.

## 

## **Slash Commands**

* /go — Toggle main UI window  
* /go help — Print command list to chat  
* /go setalt \<alt\> \<main\> — Tag alt relationship  
* /go unalt \<name\> — Remove alt tag  
* /go alts — Dump current alt→main map to chat  
* /go clear — Wipe current guild's event log  
* /go bladd \<name\> — Add player to the blacklist (Auto Guild \+ Group)  
* /go bl (or blacklist/blist) — Print current blacklist to chat

## 

## **Technical Information**

* **Interface TOC**: 30300 (WotLK 3.3.5a native)  
* **Current Version**: 1.0  
* **SavedVariables**: GildeaOrdoDB (account) – guilds, macros, batchSize, spamTotalMinutes, minimap settings, **blacklist**, **blacklistReply**

* **SavedVariablesPerCharacter**: GildeaOrdoCharDB – open/close with guild, massPromote history, and autoInvite configurations.  
* **Files**: Core.lua (and modules), UI\_Main.lua (and modules), Roster.lua

* **Key Patterns Used**: scheduleDiff, ProcessBatch, containsTriggerWord, dynamic FauxScroll handling, classic frame positioning

## 

## **⚖️ Use at Your Own Discretion**

Guildera Ordo gives you serious power. Use responsibly on your realm.  
The Mass Kick and Mass Promotion tools are powerful features designed to streamline high-volume guild management, but they must be used with extreme caution. While the addon includes safeguards like double-confirmation prompts, you should always carefully review the generated candidate list before executing these batch operations to prevent unintended roster changes.   
The new Blacklist is a powerful tool to protect your auto-invite systems. Everything is rate-limited and double-confirmed where appropriate, but **you** are responsible for the names you add to the blacklist and whitelist. 

Refined for WotLK 3.3.5a – pure Lua, no external dependencies. v1.0 — Modular UI, Purge Blacklist, Auto-Invite DB Migration, Dynamic Blacklist Search.