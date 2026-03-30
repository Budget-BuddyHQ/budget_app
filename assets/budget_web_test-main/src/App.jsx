// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 1
// CSS · THEME · WORLD CONSTANTS · FINANCE ENGINE
// ═══════════════════════════════════════════════════════════════
import { useState, useEffect, useCallback, useRef, useMemo, useReducer, memo } from "react";

export const GLOBAL_CSS = `
@import url('https://fonts.googleapis.com/css2?family=Fredoka+One&family=Nunito:wght@400;600;700;800;900&display=swap');

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html, body, #root {
  width: 100%; height: 100%;
  overflow: hidden;
  background: #0a0818;
  font-family: 'Nunito', sans-serif;
}

/* ─── Game Container ─────────────────────────────────── */
#game-container {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

/* ─── Scrollbars ─────────────────────────────────────── */
::-webkit-scrollbar { width: 4px; height: 4px; }
::-webkit-scrollbar-track { background: rgba(0,0,0,.3); }
::-webkit-scrollbar-thumb { background: rgba(255,215,0,.4); border-radius: 4px; }

/* ════════════════════════════════════════════════════════
   KEYFRAMES
   ════════════════════════════════════════════════════════ */
@keyframes floatIdle    { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-8px)} }
@keyframes walkBob      { 0%,100%{transform:translateY(0) scaleX(var(--face,1))} 25%{transform:translateY(-6px) scaleX(var(--face,1))} 75%{transform:translateY(6px) scaleX(var(--face,1))} }
@keyframes bobPet       { 0%,100%{transform:translateY(0) scale(1)} 50%{transform:translateY(-6px) scale(1.05)} }
@keyframes monWander    { 0%,100%{transform:translateY(0)} 33%{transform:translateY(-4px)} 66%{transform:translateY(3px)} }
@keyframes enemyFloat   { 0%,100%{transform:translateY(0) scale(1)} 50%{transform:translateY(-10px) scale(1.06)} }
@keyframes victoryDance { 0%,100%{transform:translateY(0) rotate(0)} 20%{transform:translateY(-16px) rotate(-10deg)} 40%{transform:translateY(-12px) rotate(10deg)} 60%{transform:translateY(-18px) rotate(-6deg)} 80%{transform:translateY(-10px) rotate(6deg)} }
@keyframes shake        { 0%,100%{transform:translateX(0)} 20%{transform:translateX(-12px)} 40%{transform:translateX(12px)} 60%{transform:translateX(-8px)} 80%{transform:translateX(8px)} }
@keyframes screenShake  { 0%,100%{transform:translate(0,0)} 15%{transform:translate(-10px,5px)} 30%{transform:translate(10px,-5px)} 45%{transform:translate(-6px,8px)} 60%{transform:translate(6px,-3px)} 75%{transform:translate(-4px,4px)} }
@keyframes slideDown    { from{transform:translateY(-24px);opacity:0} to{transform:translateY(0);opacity:1} }
@keyframes slideUp      { from{transform:translateY(24px);opacity:0} to{transform:translateY(0);opacity:1} }
@keyframes slideInLeft  { from{transform:translateX(-40px);opacity:0} to{transform:translateX(0);opacity:1} }
@keyframes slideInRight { from{transform:translateX(40px);opacity:0} to{transform:translateX(0);opacity:1} }
@keyframes popIn        { 0%{transform:scale(.4) translateY(20px);opacity:0} 70%{transform:scale(1.08)} 100%{transform:scale(1) translateY(0);opacity:1} }
@keyframes popInCenter  { 0%{transform:translate(-50%,-50%) scale(.4);opacity:0} 70%{transform:translate(-50%,-50%) scale(1.06)} 100%{transform:translate(-50%,-50%) scale(1);opacity:1} }
@keyframes pulseGold    { 0%,100%{box-shadow:0 0 0 rgba(255,215,0,0)} 50%{box-shadow:0 0 28px rgba(255,215,0,.8)} }
@keyframes pulseGreen   { 0%,100%{box-shadow:0 0 0 rgba(76,175,80,0)} 50%{box-shadow:0 0 22px rgba(76,175,80,.8)} }
@keyframes pulsePurple  { 0%,100%{box-shadow:0 0 0 rgba(156,39,176,0)} 50%{box-shadow:0 0 22px rgba(156,39,176,.85)} }
@keyframes pulseRed     { 0%,100%{box-shadow:0 0 0 rgba(244,67,54,0)} 50%{box-shadow:0 0 22px rgba(244,67,54,.85)} }
@keyframes dmgFloat     { 0%{transform:translateY(0) scale(1.2);opacity:1} 40%{transform:translateY(-50px) scale(1.4);opacity:1} 100%{transform:translateY(-90px) scale(.7);opacity:0} }
@keyframes healFloat    { 0%{transform:translateY(0) scale(1.2);opacity:1} 100%{transform:translateY(-80px) scale(.8);opacity:0} }
@keyframes critFloat    { 0%{transform:translateY(0) scale(1.6) rotate(-8deg);opacity:1} 100%{transform:translateY(-100px) scale(.6) rotate(8deg);opacity:0} }
@keyframes correctPulse { 0%,100%{transform:translate(-50%,-50%) scale(1)} 40%{transform:translate(-50%,-50%) scale(1.04)} }
@keyframes wrongShake   { 0%,100%{transform:translate(-50%,-50%) translateX(0)} 20%{transform:translate(-50%,-50%) translateX(-12px)} 40%{transform:translate(-50%,-50%) translateX(12px)} 60%{transform:translate(-50%,-50%) translateX(-8px)} 80%{transform:translate(-50%,-50%) translateX(8px)} }
@keyframes castCharge   { 0%{filter:brightness(1) saturate(1)} 50%{filter:brightness(2.4) saturate(2.5) hue-rotate(30deg)} 100%{filter:brightness(3.2) saturate(3.5)} }
@keyframes castRelease  { 0%{transform:scale(1)} 30%{transform:scale(1.6)} 65%{transform:scale(.82)} 100%{transform:scale(1)} }
@keyframes petCharge    { 0%{transform:translateX(0)} 100%{transform:translateX(220px)} }
@keyframes petReturn    { 0%{transform:translateX(220px)} 100%{transform:translateX(0)} }
@keyframes petHit       { 0%,100%{transform:scale(1) rotate(0)} 50%{transform:scale(1.7) rotate(-18deg)} }
@keyframes enemyHit     { 0%,100%{filter:brightness(1)} 50%{filter:brightness(3) saturate(0) invert(.4)} }
@keyframes enemyAttackLunge { 0%,100%{transform:translateX(0)} 40%{transform:translateX(-80px)} 70%{transform:translateX(30px)} }
@keyframes heartFloat   { 0%{transform:translateY(0) scale(0);opacity:0} 40%{transform:translateY(-40px) scale(1.3);opacity:1} 100%{transform:translateY(-90px) scale(.7);opacity:0} }
@keyframes shimmer      { 0%{background-position:-200% center} 100%{background-position:200% center} }
@keyframes particleFly  { 0%{opacity:1;transform:translate(0,0) scale(1)} 100%{opacity:0;transform:translate(var(--tx),var(--ty)) scale(0)} }
@keyframes statusPop    { from{transform:scale(0) rotate(-20deg);opacity:0} to{transform:scale(1) rotate(0);opacity:1} }
@keyframes zoneWipe     { from{opacity:0;transform:scale(1.04)} to{opacity:1;transform:scale(1)} }
@keyframes orbitOrb     { 0%{transform:rotate(0deg) translateX(48px) rotate(0deg)} 100%{transform:rotate(360deg) translateX(48px) rotate(-360deg)} }
@keyframes cloudDrift   { from{transform:translateX(-120px)} to{transform:translateX(110vw)} }
@keyframes typewriterBlink { 0%,100%{opacity:1} 50%{opacity:0} }
@keyframes spellCardHover { to{transform:translateY(-8px) scale(1.05);box-shadow:0 12px 32px rgba(0,0,0,.5);} }
@keyframes actionBarSlideUp { from{transform:translateY(120%);opacity:0} to{transform:translateY(0);opacity:1} }
@keyframes spellGridOpen { from{transform:translateY(20px) scaleY(.8);opacity:0} to{transform:translateY(0) scaleY(1);opacity:1} }
@keyframes battleBgPulse { 0%,100%{opacity:.85} 50%{opacity:1} }
@keyframes hpBarFill    { from{width:0} to{width:var(--hp-pct)} }
@keyframes scrollUnfurl { from{transform:translate(-50%,-50%) scaleY(.1);opacity:0} to{transform:translate(-50%,-50%) scaleY(1);opacity:1} }
@keyframes glowPulse    { 0%,100%{text-shadow:0 0 8px currentColor} 50%{text-shadow:0 0 24px currentColor, 0 0 48px currentColor} }
@keyframes tilePop      { 0%{opacity:.7;transform:scale(.5)} 100%{opacity:0;transform:scale(1.8)} }
@keyframes dialogueFadeIn { from{transform:translateX(-50%) translateY(12px);opacity:0} to{transform:translateX(-50%) translateY(0);opacity:1} }

/* ════════════════════════════════════════════════════════
   SHARED COMPONENT CLASSES
   ════════════════════════════════════════════════════════ */

/* Ghost UI Layer — pointer-events passthrough */
.hud-layer {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  pointer-events: none;
  z-index: 8000;
}
.hud-interactive {
  pointer-events: auto;
}

/* Game Button */
.gbtn {
  cursor: pointer;
  transition: transform .12s ease, filter .12s ease, box-shadow .12s ease;
  user-select: none;
  border: none;
  font-family: 'Fredoka One', cursive;
  outline: none;
  pointer-events: auto;
}
.gbtn:hover:not(:disabled) {
  transform: translateY(-3px) scale(1.07);
  filter: brightness(1.15);
}
.gbtn:active:not(:disabled) {
  transform: scale(.93) translateY(1px);
}
.gbtn:disabled {
  opacity: .32;
  cursor: not-allowed;
  pointer-events: none;
}

/* Stat Bars */
.sbt  { border-radius: 999px; overflow: hidden; background: rgba(0,0,0,.55); border: 1.5px solid rgba(255,255,255,.1); }
.sbf  { border-radius: 999px; height: 100%; transition: width .55s cubic-bezier(.4,0,.2,1); }

/* Spell Card */
.spcard {
  cursor: pointer;
  transition: transform .18s ease, box-shadow .18s ease;
  outline: none;
  user-select: none;
  pointer-events: auto;
}
.spcard:hover:not(.sp-disabled) {
  transform: translateY(-8px) scale(1.06);
  box-shadow: 0 16px 40px rgba(0,0,0,.55);
}
.spcard.sp-sel   { animation: pulsePurple 1.1s ease-in-out infinite; }
.spcard.sp-disabled { opacity: .25; cursor: not-allowed; }

/* Damage Numbers */
.dmg-crit { position:absolute; pointer-events:none; font-family:'Fredoka One',cursive; font-weight:900; text-shadow:2px 2px 0 rgba(0,0,0,.95); animation:critFloat 1.3s ease-out forwards; z-index:9999; white-space:nowrap; }
.dmg-norm { position:absolute; pointer-events:none; font-family:'Fredoka One',cursive; font-weight:900; text-shadow:2px 2px 0 rgba(0,0,0,.95); animation:dmgFloat 1.1s ease-out forwards; z-index:9999; white-space:nowrap; }
.dmg-heal { position:absolute; pointer-events:none; font-family:'Fredoka One',cursive; font-weight:900; text-shadow:1px 1px 0 rgba(0,0,0,.9); animation:healFloat 1.2s ease-out forwards; z-index:9999; white-space:nowrap; }

/* Modal Backdrop */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.78);
  backdrop-filter: blur(6px);
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: auto;
}

/* Parchment Modal */
.modal-parchment {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%,-50%);
  background: linear-gradient(160deg, #1e1630 0%, #2a1d45 40%, #1a1228 100%);
  border: 3px solid;
  border-image: linear-gradient(135deg, #FFD700, #B8860B, #FFD700, #B8860B) 1;
  border-radius: 24px;
  box-shadow:
    0 0 0 1px rgba(255,215,0,.15),
    0 0 48px rgba(255,215,0,.25),
    0 32px 80px rgba(0,0,0,.8),
    inset 0 1px 0 rgba(255,255,255,.07);
  pointer-events: auto;
  z-index: 10001;
}
.modal-parchment::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(160deg, rgba(255,215,0,.06) 0%, transparent 40%);
  pointer-events: none;
}

/* Stone Modal (for battle/quests) */
.modal-stone {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%,-50%);
  background: linear-gradient(155deg, #12101e 0%, #1c1830 50%, #0e0c18 100%);
  border: 2px solid rgba(255,255,255,.1);
  border-radius: 20px;
  box-shadow:
    0 0 0 1px rgba(255,255,255,.05),
    0 24px 64px rgba(0,0,0,.9),
    inset 0 1px 0 rgba(255,255,255,.06);
  pointer-events: auto;
  z-index: 10001;
}

/* Zone transition */
.zone-enter { animation: zoneWipe .5s ease; }

/* Rarity shimmers */
.rarity-epic::after, .rarity-legendary::after {
  content: '';
  position: absolute;
  inset: 0;
  pointer-events: none;
  border-radius: inherit;
  background-size: 200% 100%;
  animation: shimmer 2s ease-in-out infinite;
}
.rarity-epic { position:relative; overflow:hidden; }
.rarity-epic::after { background: linear-gradient(105deg, transparent 33%, rgba(156,39,176,.35) 50%, transparent 67%); }
.rarity-legendary { position:relative; overflow:hidden; }
.rarity-legendary::after { background: linear-gradient(105deg, transparent 18%, rgba(255,215,0,.45) 35%, rgba(255,255,255,.22) 50%, rgba(255,215,0,.45) 65%, transparent 82%); animation-duration: 1.6s; }

/* Map entity hover */
.map-ent { transition: filter .14s ease; cursor: pointer; }
.map-ent:hover { filter: brightness(1.3) drop-shadow(0 0 8px rgba(255,215,0,.7)); }

/* Action Bar */
.action-bar {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 30%;
  min-height: 180px;
  max-height: 260px;
   z-index: 100; 
  background: linear-gradient(0deg, rgba(8,5,18,.98) 0%, rgba(10,7,22,.95) 70%, rgba(12,8,24,.85) 100%);
  border-top: 2px solid rgba(255,215,0,.2);
  pointer-events: auto;
  display: flex;
  flex-direction: column;
  padding: 12px 16px 14px;
  gap: 10px;
  animation: actionBarSlideUp .28s ease;
  backdrop-filter: blur(12px);
  box-shadow: 0 -8px 40px rgba(0,0,0,.6);
}

/* Typewriter cursor */
.typewriter-cursor {
  display: inline-block;
  width: 2px;
  height: 1em;
  background: currentColor;
  vertical-align: text-bottom;
  animation: typewriterBlink 0.8s step-start infinite;
  margin-left: 2px;
}

/* Dialogue Box */
.dialogue-box {
  position: absolute;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  width: min(680px, 92vw);
  background: linear-gradient(155deg, #0e0c1e 0%, #1a1530 100%);
  border: 2.5px solid rgba(255,215,0,.4);
  border-radius: 20px;
  box-shadow:
    0 0 0 1px rgba(255,215,0,.1),
    0 16px 48px rgba(0,0,0,.8),
    inset 0 1px 0 rgba(255,255,255,.06);
  pointer-events: auto;
  animation: dialogueFadeIn .32s ease;
  overflow: hidden;
}
.dialogue-box::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(255,215,0,.5), transparent);
}

/* HP Bar floating nameplate */
.nameplate {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  pointer-events: none;
  filter: drop-shadow(0 2px 8px rgba(0,0,0,.8));
}
.nameplate-name {
  font-family: 'Fredoka One', cursive;
  font-size: 11px;
  color: #fff;
  text-shadow: 1px 1px 0 rgba(0,0,0,.9);
  white-space: nowrap;
}
.nameplate-hp-track {
  width: 90px;
  height: 7px;
  background: rgba(0,0,0,.6);
  border-radius: 999px;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,.15);
}
.nameplate-hp-fill {
  height: 100%;
  border-radius: 999px;
  transition: width .55s cubic-bezier(.4,0,.2,1);
}
`;

// ─── Theme Tokens ──────────────────────────────────────────────
export const T = {
  gold:    "#FFD700",
  goldD:   "#B8860B",
  goldL:   "#FFE55C",
  goldGlow:"rgba(255,215,0,.32)",
  purple:  "#9C27B0",
  purpleL: "#CE93D8",
  purpleD: "#6A1B9A",
  green:   "#4CAF50",
  greenL:  "#69F0AE",
  greenD:  "#2E7D32",
  teal:    "#00BCD4",
  red:     "#F44336",
  redD:    "#C62828",
  blue:    "#2196F3",
  blueD:   "#1565C0",
  orange:  "#FF6B35",
  panel:   "rgba(8,5,20,.94)",
  panelL:  "rgba(14,10,30,.92)",
  glass:   "rgba(255,255,255,.05)",
  fontD:   "'Fredoka One',cursive",
  fontB:   "'Nunito',sans-serif",
};

export const RC = {
  common:    { color: "#9E9E9E", glow: "rgba(158,158,158,.3)" },
  uncommon:  { color: "#4CAF50", glow: "rgba(76,175,80,.35)" },
  rare:      { color: "#2196F3", glow: "rgba(33,150,243,.35)" },
  epic:      { color: "#9C27B0", glow: "rgba(156,39,176,.4)" },
  legendary: { color: "#FFD700", glow: "rgba(255,215,0,.45)" },
};

// ─── World Constants ───────────────────────────────────────────
export const MAP_COLS      = 20;
export const MAP_ROWS      = 12;
export const MON_RESPAWN   = 90;
export const CHEST_RESPAWN = 150;
export const TICK_MS       = 1000;
export const MAX_LV        = 15;
export const PROX_DIST     = 1.5;

export const PHASE_T = {
  CAST_CHARGE:    700,
  CAST_RELEASE:   440,
  PET_ADVANCE:    360,
  PET_HIT:        260,
  PET_RETREAT:    320,
  ENEMY_TURN_GAP: 420,
  ENEMY_ATTACK:   580,
};

// ─── Tile Definitions ──────────────────────────────────────────
export const TILE = {
  GRASS:0, PATH:1, WATER:2, TREE:3, ROCK:4,
  WALL:5, DARK:6, FLOWER:7, DUNGEON:8, LAVA:9, BRIDGE:10,
};

export const WALKABLE = new Set([
  TILE.GRASS, TILE.PATH, TILE.DARK, TILE.FLOWER, TILE.DUNGEON, TILE.BRIDGE,
]);

export const TILE_GFX = {
  [TILE.GRASS]:   { bg:"#4a8a2c", alt:"#4f962e", emoji:null,  canopy:null },
  [TILE.PATH]:    { bg:"#c4a86a", alt:"#bca062", emoji:null,  canopy:null },
  [TILE.WATER]:   { bg:"#2a6ec8", alt:"#1d5db8", emoji:"〰️", canopy:null },
  [TILE.TREE]:    { bg:"#2a6018", alt:"#245214", emoji:"🪵",  canopy:"🌲" },
  [TILE.ROCK]:    { bg:"#6e6254", alt:"#5e5244", emoji:"🪨",  canopy:null },
  [TILE.WALL]:    { bg:"#2a2a3a", alt:"#242232", emoji:null,  canopy:null },
  [TILE.DARK]:    { bg:"#1e3d12", alt:"#1a3410", emoji:null,  canopy:null },
  [TILE.FLOWER]:  { bg:"#5aaa36", alt:"#54a030", emoji:"🌸",  canopy:null },
  [TILE.DUNGEON]: { bg:"#181820", alt:"#131318", emoji:null,  canopy:null },
  [TILE.LAVA]:    { bg:"#8a2200", alt:"#741c00", emoji:"🔥",  canopy:null },
  [TILE.BRIDGE]:  { bg:"#c09050", alt:"#b08040", emoji:null,  canopy:null },
};

// ─── PRNG ──────────────────────────────────────────────────────
export function mulberry32(seed) {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

let _uid = 0;
export function makeUUID() {
  return `sq_${Date.now().toString(36)}_${(++_uid).toString(36)}`;
}

// ─── A* Pathfinding ────────────────────────────────────────────
export function aStarTile(sx, sy, ex, ey, walkableFn) {
  const key = (x,y) => `${x},${y}`;
  const h   = (x,y) => Math.abs(x-ex)+Math.abs(y-ey);
  if (!walkableFn(ex,ey)) return [];
  if (sx===ex && sy===ey) return [];
  const open   = new Map([[key(sx,sy),[sx,sy]]]);
  const closed = new Set();
  const gScore = {[key(sx,sy)]:0};
  const fScore = {[key(sx,sy)]:h(sx,sy)};
  const from   = {};
  let iter = 0;
  while (open.size>0 && iter++<500) {
    let cur=null, loF=Infinity;
    for (const [k] of open) if ((fScore[k]??Infinity)<loF){loF=fScore[k];cur=k;}
    if (!cur) break;
    const [cx,cy] = open.get(cur);
    if (cx===ex && cy===ey) {
      const path=[]; let c=cur;
      while (from[c]){path.unshift(c.split(",").map(Number));c=from[c];}
      path.push([ex,ey]); return path;
    }
    open.delete(cur); closed.add(cur);
    for (const [nx,ny] of [[cx-1,cy],[cx+1,cy],[cx,cy-1],[cx,cy+1]]) {
      if (!walkableFn(nx,ny)) continue;
      const nk=key(nx,ny);
      if (closed.has(nk)) continue;
      const tg=(gScore[cur]??0)+1;
      if (!open.has(nk)||tg<(gScore[nk]??Infinity)) {
        from[nk]=cur; gScore[nk]=tg; fScore[nk]=tg+h(nx,ny);
        open.set(nk,[nx,ny]);
      }
    }
  }
  return [[ex,ey]];
}

export function getZoneTier(zx,zy) {
  if (zx===0&&zy===0)  return 1;
  if (zx===0&&zy===-1) return 2;
  if (zx===0&&zy===-2) return 3;
  return Math.min(3,Math.max(1,Math.abs(zx)+Math.abs(zy)));
}

// ════════════════════════════════════════════════════════════════
// FINANCE ENGINE
// ════════════════════════════════════════════════════════════════
const T1 = [
  ()=>{
    const budget=(Math.floor(Math.random()*5)+3)*50;
    const price=(Math.floor(Math.random()*4)+1)*20;
    const qty=Math.floor(Math.random()*3)+2;
    const cost=price*qty; const left=budget-cost;
    return { category:"Party Budget", scenario:"The Harvest Feast",
      question:`Your party fund is ${budget}g. Healing potions cost ${price}g each. You buy ${qty}. How much gold remains?`,
      correctAnswer:Math.max(0,left), wrong:[cost,budget,Math.abs(left-price)],
      explanation:`${qty} × ${price}g = ${cost}g spent. ${budget} − ${cost} = ${left}g left` };
  },
  ()=>{
    const earn=(Math.floor(Math.random()*5)+2)*40;
    const food=Math.floor(earn*.25),rent=Math.floor(earn*.35),fun=Math.floor(earn*.15);
    const save=earn-food-rent-fun;
    return { category:"Monthly Budget", scenario:"Hero's Allowance",
      question:`Monthly earnings: ${earn}g. Food ${food}g · Rent ${rent}g · Fun ${fun}g. How much can you save?`,
      correctAnswer:save, wrong:[earn,food+rent,earn-food],
      explanation:`${earn} − ${food} − ${rent} − ${fun} = ${save}g saved` };
  },
  ()=>{
    const base=(Math.floor(Math.random()*4)+2)*50;
    const pct=(Math.floor(Math.random()*3)+1)*10;
    const discount=Math.floor(base*pct/100);
    return { category:"Discounts", scenario:"Flash Sale at the Forge",
      question:`A runic sword costs ${base}g. A ${pct}% discount is applied. What is the final price?`,
      correctAnswer:base-discount, wrong:[base+discount,discount,base],
      explanation:`${pct}% of ${base}g = ${discount}g off. Final = ${base} − ${discount} = ${base-discount}g` };
  },
  ()=>{
    const price=Math.floor(Math.random()*5)+3;
    const items=Math.floor(Math.random()*4)+3;
    const paid=Math.ceil((price*items)/5)*5;
    const change=paid-price*items;
    return { category:"Making Change", scenario:"The Item Shop",
      question:`${items} items at ${price}g each. You hand over ${paid}g. How much change?`,
      correctAnswer:change, wrong:[price*items,change+5,Math.abs(change-price)],
      explanation:`Total = ${items}×${price} = ${price*items}g. Change = ${paid} − ${price*items} = ${change}g` };
  },
  ()=>{
    const weekly=(Math.floor(Math.random()*4)+2)*25;
    const goal=weekly*(Math.floor(Math.random()*4)+4);
    const weeks=goal/weekly;
    return { category:"Savings Goal", scenario:"Saving for Armour",
      question:`You save ${weekly}g per week. Armour costs ${goal}g. How many weeks to save up?`,
      correctAnswer:weeks, wrong:[weeks-1,weeks+2,Math.floor(goal/(weekly*1.5))],
      explanation:`Weeks = ${goal} ÷ ${weekly} = ${weeks}` };
  },
];

const T2 = [
  ()=>{
    const P=(Math.floor(Math.random()*5)+1)*100;
    const r=Math.floor(Math.random()*5)+4;
    const t=Math.floor(Math.random()*3)+2;
    const I=Math.floor(P*r/100*t);
    return { category:"Simple Interest", scenario:"Kingdom Bank Deposit",
      question:`You deposit ${P}g at ${r}% annual interest (I=P×r×t). After ${t} years, total interest earned?`,
      correctAnswer:I, wrong:[P+I,Math.floor(P*r/100),I+15],
      explanation:`I = ${P} × ${r/100} × ${t} = ${I}g` };
  },
  ()=>{
    const cost=(Math.floor(Math.random()*5)+2)*60;
    const benefit=Math.floor(Math.random()*4)+5;
    const breaks=Math.ceil(cost/benefit);
    return { category:"Break-Even", scenario:"The Forge Upgrade",
      question:`A forge upgrade costs ${cost}g but saves ${benefit}g per craft. How many crafts to break even?`,
      correctAnswer:breaks, wrong:[breaks-1,breaks+3,Math.floor(cost/benefit)],
      explanation:`Break-even = ⌈${cost} ÷ ${benefit}⌉ = ${breaks} crafts` };
  },
  ()=>{
    const income=(Math.floor(Math.random()*5)+3)*80;
    const saved=Math.floor(income*.30);
    const months=Math.floor(Math.random()*4)+4;
    return { category:"Savings Planning", scenario:"Dragon's Hoard Fund",
      question:`You earn ${income}g/month and save 30%. After ${months} months, total saved?`,
      correctAnswer:saved*months, wrong:[income*months,saved,saved*months+saved],
      explanation:`30% of ${income}g = ${saved}g/month × ${months} = ${saved*months}g` };
  },
  ()=>{
    const A=(Math.floor(Math.random()*4)+1)*100;
    const rA=Math.floor(Math.random()*2)+3;
    const rB=rA+Math.floor(Math.random()*3)+2;
    const diff=Math.floor(A*(rB-rA)/100);
    return { category:"Comparing Rates", scenario:"Which Bank Wins?",
      question:`Bank A: ${rA}% on ${A}g. Bank B: ${rB}% on ${A}g. How much MORE interest does Bank B give per year?`,
      correctAnswer:diff, wrong:[Math.floor(A*rA/100),Math.floor(A*rB/100),diff*2],
      explanation:`Extra = ${A} × ${rB-rA}/100 = ${diff}g` };
  },
  ()=>{
    const price=(Math.floor(Math.random()*4)+3)*100;
    const down=Math.floor(price*.20);
    const loan=price-down;
    const rate=Math.floor(Math.random()*3)+5;
    const interest=Math.floor(loan*rate/100);
    return { category:"Down Payments", scenario:"Buy the Hero's Keep",
      question:`A keep costs ${price}g. 20% down (${down}g). The ${loan}g loan has ${rate}% annual fee. Interest for 1 year?`,
      correctAnswer:interest, wrong:[down,loan,interest+down],
      explanation:`Loan = ${loan}g × ${rate}/100 = ${interest}g` };
  },
];

const T3 = [
  ()=>{
    const invest=(Math.floor(Math.random()*4)+2)*50;
    const prob=(Math.floor(Math.random()*4)+2)*10;
    const bigR=invest*(Math.floor(Math.random()*3)+3);
    const smallR=Math.floor(invest*.1);
    const EV=Math.round((prob/100)*bigR+((100-prob)/100)*smallR-invest);
    const ans=EV>0?"Take the bet":"Skip the bet";
    return { category:"Expected Value", scenario:"The Dragon's Wager",
      question:`Risk ${invest}g: ${prob}% chance of winning ${bigR}g, ${100-prob}% chance of getting ${smallR}g back. EV = ${EV}g. Take it?`,
      correctAnswer:ans, wrong:[EV>0?"Skip the bet":"Take the bet"],
      explanation:`EV = ${(prob/100).toFixed(1)}×${bigR} + ${((100-prob)/100).toFixed(1)}×${smallR} − ${invest} = ${EV}g` };
  },
  ()=>{
    const P=(Math.floor(Math.random()*4)+1)*100;
    const r=Math.floor(Math.random()*3)+4;
    const t=Math.floor(Math.random()*2)+2;
    let val=P; for(let i=0;i<t;i++) val=Math.floor(val*(1+r/100));
    const gain=val-P, simple=Math.floor(P*r/100*t);
    return { category:"Compound Interest", scenario:"The Gold Vault",
      question:`${P}g at ${r}% compounded for ${t} months. Compound gain? (Simple would give ${simple}g)`,
      correctAnswer:gain, wrong:[simple,gain+12,gain-10],
      explanation:`${P}×(1+${r/100})^${t} ≈ ${val}g → Gain = ${gain}g` };
  },
  ()=>{
    const goldA=(Math.floor(Math.random()*4)+3)*20;
    const goldB=Math.floor(goldA*.4);
    const xpB=goldA*2;
    const totalB=goldB+xpB*.5;
    const ans=totalB>goldA?"Option B":"Option A";
    return { category:"Opportunity Cost", scenario:"The Merchant's Trade-Off",
      question:`Option A: ${goldA}g cash. Option B: ${goldB}g + ${xpB}xp (1xp = 0.5g). Which is worth more?`,
      correctAnswer:ans, wrong:[ans==="Option A"?"Option B":"Option A"],
      explanation:`A=${goldA}g. B=${goldB}+${xpB}×0.5=${totalB}g. ${ans} wins!` };
  },
  ()=>{
    const income=(Math.floor(Math.random()*5)+4)*100;
    const expense=(Math.floor(Math.random()*5)+2)*50;
    const goal=(Math.floor(Math.random()*5)+8)*100;
    const monthly=income-expense;
    const needed=Math.ceil(goal/monthly);
    return { category:"Financial Planning", scenario:"The Legendary Weapon Fund",
      question:`Income: ${income}g/month. Expenses: ${expense}g/month. Legendary weapon costs ${goal}g. Months to save?`,
      correctAnswer:needed, wrong:[needed-1,needed+2,Math.floor(goal/income)],
      explanation:`Monthly savings = ${monthly}g. ⌈${goal}÷${monthly}⌉ = ${needed} months` };
  },
  ()=>{
    const P=(Math.floor(Math.random()*5)+2)*100;
    const r=Math.floor(Math.random()*4)+5;
    let compound=P; for(let i=0;i<3;i++) compound=Math.floor(compound*(1+r/100));
    const simple=P+Math.floor(P*r/100*3);
    const diff=compound-simple;
    return { category:"Compound vs Simple", scenario:"Long-Term Strategy",
      question:`${P}g invested for 3 years at ${r}%/yr. Compound: ${compound}g vs Simple: ${simple}g. Extra from compounding?`,
      correctAnswer:diff, wrong:[compound,simple,diff+5],
      explanation:`${compound}g − ${simple}g = ${diff}g extra` };
  },
];

export function generateFinanceQuestion(zx=0, zy=0) {
  const tier=getZoneTier(zx,zy);
  const pool=tier===1?T1:tier===2?T2:T3;
  const raw=pool[Math.floor(Math.random()*pool.length)]();
  const {correctAnswer,wrong}=raw;
  const options=[correctAnswer,...(wrong||[]).filter(a=>String(a)!==String(correctAnswer))].slice(0,4);
  while(options.length<4) options.push(options[0]);
  const answers=options.sort(()=>Math.random()-.5);
  return { ...raw, answers, tier,
    difficulty:tier===1?"Easy":tier===2?"Medium":"Hard",
    bonusMultiplier:tier===1?1.3:tier===2?1.5:1.8 };
}
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 2
// GAME DATA
// ═══════════════════════════════════════════════════════════════

const C2T = {
  ".":TILE.GRASS, p:TILE.PATH, w:TILE.WATER, t:TILE.TREE,
  r:TILE.ROCK, b:TILE.WALL, d:TILE.DARK, f:TILE.FLOWER,
  u:TILE.DUNGEON, l:TILE.LAVA, B:TILE.BRIDGE,
};

function parseTileMap(rows) {
  return rows.map(row=>row.split("").map(c=>C2T[c]??TILE.GRASS));
}

const TOWN_MAP = parseTileMap([
   "tttttttttppttttttttt",   // row 0: gap at col 9-10
  "t........pp........t",   // row 1: open path
  "t....pp......pp....t",
  "t...pppp....pppp...t",
  "t....pp.....pp.....t",
  "t..fff...pp....ff..t",
  "t.......pppp.......t",
  "t....pp..pp..pp....t",
  "t...pppp......pppp.t",
  "t....pp....fff.pp..t",
  "t..................t",
  "tttttttttttttttttttt",
]);

const WOODS_MAP = parseTileMap([
  "tttttttttppttttttttt",
  "ttd.ddt...dd..tttddt",
  "td.dddd....d..tt.ddt",
  "tdd..ddd.ddd..t..ddt",
  "tddddddd..d...tt.ddt",
  "td..dddd.ddd..t..ddt",
  "tdd.ddd...d...tt.ddt",
  "tdd.dddd.ddd..t..ddt",
  "tdddddrr..d...tt.ddt",
  "td..ddrr.ddd..t..ddt",
  "td...ddd...d..tt.ddt",
  "tttttttttppttttttttt",   // row 11: gap at col 9-10
]);

const DUNGEON_MAP = parseTileMap([
  "bbbbbbbbbppbbbbbbbbb",
  "buuuuuuuuuuuuuuuuuub",
  "buuuruuuuuuuuuurruub",
  "buuuuuuuurrruuuuuuub",
  "buuuuuurrruuuuuuuuub",
  "brrruuuuuuuuuuuurrrb",
  "buuuuuuuuuuuuuuuuuub",
  "buuuuuurrruuuuuuuuub",
  "buuuuruuuuuuuuuuruub",
  "buuuuuuuuuuuuuuuuuub",
  "buuuuuuuuuuuuuuuuuub",
  "bbbbbbbbbppbbbbbbbbb",
]);

export const ZONE_TILE_MAPS = { "0_0":TOWN_MAP, "0_-1":WOODS_MAP, "0_-2":DUNGEON_MAP };

export function getZoneTileMap(zx,zy) {
  return ZONE_TILE_MAPS[`${zx}_${zy}`]||TOWN_MAP;
}

export function isTileWalkable(tileMap,tx,ty) {
  if(tx<0||ty<0||tx>=MAP_COLS||ty>=MAP_ROWS) return false;
  const t=tileMap[ty]?.[tx];
  return t!==undefined && WALKABLE.has(t);
}

export const ELEM_CHAIN = {
  fire:"ice", ice:"earth", earth:"storm", storm:"water", water:"fire", astral:"astral",
};

export function elemMult(atk,def) {
  if(ELEM_CHAIN[atk]===def) return 1.5;
  if(ELEM_CHAIN[def]===atk) return 0.67;
  if(atk==="astral"&&def!=="astral") return 1.25;
  return 1.0;
}

export const XP_TABLE = [0,120,280,480,730,1050,1460,1970,2600,3400,4500,6200,8500,11000,14500,19000];
export function xpFor(lv) { return XP_TABLE[Math.min(lv,XP_TABLE.length-1)]??lv*650; }

// ─── Spell Visuals Config ──────────────────────────────────────
// Each spell has a `vfx` field used by BattleArena for the cast animation
export const SPELLS = {
  starbit:        {id:"starbit",        name:"Starbit",        elem:"astral", power:42, mp:16, emoji:"✨", color:"#CE93D8", tier:1, minLv:1,  desc:"Sparkles of stardust.",     vfx:"sparkle" },
  fireball:       {id:"fireball",       name:"Fireball",       elem:"fire",   power:38, mp:18, emoji:"🔥", color:"#FF6B35", tier:1, minLv:1,  desc:"A blazing arcane orb.",     vfx:"fire" },
  chill_splinter: {id:"chill_splinter", name:"Chill Splinter", elem:"ice",    power:38, mp:18, emoji:"❄️", color:"#80DEEA", tier:1, minLv:1,  desc:"Icy shards pierce the foe.",vfx:"ice" },
  leaf_burst:     {id:"leaf_burst",     name:"Leaf Burst",     elem:"earth",  power:35, mp:14, emoji:"🍃", color:"#81C784", tier:1, minLv:1,  desc:"Razor-sharp leaf volley.",  vfx:"earth" },
  tsunami:        {id:"tsunami",        name:"Tsunami",        elem:"water",  power:33, mp:15, emoji:"🌊", color:"#29B6F6", tier:1, minLv:1,  desc:"Rising ocean swell.",       vfx:"water" },
  quake:          {id:"quake",          name:"Earthshake",     elem:"earth",  power:31, mp:12, emoji:"🪨", color:"#A1887F", tier:1, minLv:1,  desc:"The ground trembles.",      vfx:"rock" },
  heal_light:     {id:"heal_light",     name:"Healing Light",  elem:"astral", power:45, mp:20, emoji:"💛", color:"#FFD700", tier:1, minLv:1,  desc:"Starlight restores HP.",    vfx:"heal", isHeal:true },
  multi_spark:    {id:"multi_spark",    name:"Multi-Spark",    elem:"storm",  power:48, mp:22, emoji:"⚡", color:"#FFD600", tier:2, minLv:3,  desc:"Triple lightning bolts.",   vfx:"lightning" },
  thunder:        {id:"thunder",        name:"Thunderclap",    elem:"storm",  power:50, mp:28, emoji:"⚡", color:"#FFD600", tier:2, minLv:3,  desc:"Divine lightning bolt.",    vfx:"thunder" },
  blizzard:       {id:"blizzard",       name:"Blizzard",       elem:"ice",    power:44, mp:24, emoji:"❄️", color:"#80DEEA", tier:2, minLv:4,  desc:"A howling ice storm.",      vfx:"blizzard" },
  tide:           {id:"tide",           name:"Dark Tide",      elem:"water",  power:55, mp:35, emoji:"🌀", color:"#0288D1", tier:2, minLv:5,  desc:"Deep-ocean vortex.",        vfx:"vortex" },
  nova:           {id:"nova",           name:"Astral Nova",    elem:"astral", power:62, mp:40, emoji:"🌟", color:"#CE93D8", tier:3, minLv:7,  desc:"Pure concentrated arcane.", vfx:"nova" },
  meteor:         {id:"meteor",         name:"Meteor Fall",    elem:"fire",   power:75, mp:55, emoji:"☄️", color:"#FF5722", tier:3, minLv:7,  desc:"A meteor from the sky.",    vfx:"meteor" },
  gale:           {id:"gale",           name:"Thundergale",    elem:"storm",  power:68, mp:46, emoji:"🌪️", color:"#FFF176", tier:3, minLv:8,  desc:"Lightning-forged hurricane.",vfx:"storm" },
  permafrost:     {id:"permafrost",     name:"Permafrost",     elem:"ice",    power:80, mp:60, emoji:"🧊", color:"#B3E5FC", tier:3, minLv:9,  desc:"Absolute-zero lance.",      vfx:"permafrost" },
  grand_heal:     {id:"grand_heal",     name:"Grand Heal",     elem:"astral", power:90, mp:48, emoji:"✨", color:"#FFEE58", tier:3, minLv:8,  desc:"Major HP restoration.",     vfx:"grand_heal", isHeal:true },
};

// ─── Bestiary ──────────────────────────────────────────────────
export const BESTIARY = {
  gloop:      {id:"gloop",      name:"Gloop Slime",    emoji:"🟢", elem:"water",  baseLv:1,  hp:55,  ak:1.0,dk:1.0,xk:1.0,gk:1.0, color:"#66BB6A", tameable:true,  drops:[{id:"hp_pot",ch:.4}],  zones:["0_0","0_-1"]},
  puddle:     {id:"puddle",     name:"Puddle Slime",   emoji:"🔵", elem:"water",  baseLv:1,  hp:45,  ak:.85,dk:.9, xk:.9, gk:.9,  color:"#42A5F5", tameable:true,  drops:[],                     zones:["0_0"]},
  shadowbat:  {id:"shadowbat",  name:"Shadow Bat",     emoji:"🦇", elem:"storm",  baseLv:2,  hp:48,  ak:1.2,dk:.8, xk:1.1,gk:1.1, color:"#9575CD", tameable:true,  drops:[{id:"mp_pot",ch:.3}],  zones:["0_0","0_-1"]},
  leaf_sprite:{id:"leaf_sprite",name:"Leaf Sprite",    emoji:"🌿", elem:"earth",  baseLv:2,  hp:52,  ak:.9, dk:1.1,xk:1.0,gk:1.0, color:"#81C784", tameable:true,  drops:[],                     zones:["0_0","0_-1"]},
  fairy:      {id:"fairy",      name:"Mischief Fairy", emoji:"🧚", elem:"astral", baseLv:2,  hp:40,  ak:1.3,dk:.7, xk:1.2,gk:1.2, color:"#F48FB1", tameable:true,  drops:[{id:"mp_pot",ch:.35}], zones:["0_0","0_-1"]},
  pyreling:   {id:"pyreling",   name:"Pyreling",       emoji:"👺", elem:"fire",   baseLv:3,  hp:72,  ak:1.4,dk:1.1,xk:1.5,gk:1.5, color:"#EF5350", tameable:true,  drops:[{id:"hp_pot",ch:.45}], zones:["0_-1"]},
  iceling:    {id:"iceling",    name:"Iceling",        emoji:"🧊", elem:"ice",    baseLv:3,  hp:68,  ak:1.2,dk:1.3,xk:1.4,gk:1.4, color:"#80DEEA", tameable:true,  drops:[],                     zones:["0_-1"]},
  stormling:  {id:"stormling",  name:"Stormling",      emoji:"⛈️", elem:"storm",  baseLv:4,  hp:80,  ak:1.5,dk:1.0,xk:1.6,gk:1.6, color:"#FFD600", tameable:true,  drops:[{id:"mp_pot",ch:.4}],  zones:["0_-1"]},
  siren:      {id:"siren",      name:"Deep Siren",     emoji:"🧜", elem:"water",  baseLv:4,  hp:88,  ak:1.4,dk:1.2,xk:1.7,gk:1.7, color:"#29B6F6", tameable:false, drops:[],                     zones:["0_-1"]},
  bouldrox:   {id:"bouldrox",   name:"Bouldrox",       emoji:"🗿", elem:"earth",  baseLv:5,  hp:110, ak:1.6,dk:1.8,xk:1.9,gk:1.9, color:"#8D6E63", tameable:false, drops:[{id:"big_pot",ch:.25}], zones:["0_-1","0_-2"]},
  frostclaw:  {id:"frostclaw",  name:"Frostclaw",      emoji:"🐲", elem:"ice",    baseLv:7,  hp:160, ak:2.2,dk:2.0,xk:3.0,gk:3.0, color:"#29B6F6", tameable:false, drops:[{id:"elixir",ch:.15}],  zones:["0_-2"]},
  blazewing:  {id:"blazewing",  name:"Blazewing",      emoji:"🔥", elem:"fire",   baseLv:7,  hp:150, ak:2.4,dk:1.8,xk:3.0,gk:3.2, color:"#FF6B35", tameable:false, drops:[{id:"big_pot",ch:.3}],  zones:["0_-2"]},
  voidshade:  {id:"voidshade",  name:"Voidshade",      emoji:"👤", elem:"astral", baseLv:8,  hp:140, ak:2.6,dk:1.6,xk:3.4,gk:3.4, color:"#CE93D8", tameable:false, drops:[{id:"elixir",ch:.2}],   zones:["0_-2"]},
  stormlord:  {id:"stormlord",  name:"Stormlord",      emoji:"🌩️", elem:"storm",  baseLv:9,  hp:200, ak:2.8,dk:2.2,xk:4.0,gk:4.0, color:"#FFF176", tameable:false, drops:[{id:"elixir",ch:.25}],  zones:["0_-2"]},
  shadowlord: {id:"shadowlord", name:"SHADOWLORD",     emoji:"👁️", elem:"storm",  baseLv:10, hp:320, ak:4.0,dk:3.5,xk:8.0,gk:8.0, color:"#7C4DFF", tameable:false, boss:true, drops:[{id:"elixir",ch:.8},{id:"crown",ch:.5},{id:"legend_staff",ch:.3}], zones:["0_-2"]},
};

export const PET_EVOLUTIONS = {
  ignis:   [{lv:15,emoji:"🦊",name:"Ignis Blaze",boost:1.4},{lv:30,emoji:"🔥",name:"Ignis Prime",boost:1.85}],
  aqua:    [{lv:15,emoji:"🐬",name:"Aqua Surge", boost:1.4},{lv:30,emoji:"🌊",name:"Aqua Ancient",boost:1.85}],
  zapfin:  [{lv:15,emoji:"🐟",name:"Zapfin Bolt",boost:1.4},{lv:30,emoji:"⚡",name:"Thunder Fin", boost:1.85}],
  frostie: [{lv:15,emoji:"🐺",name:"Frostie Rex", boost:1.4},{lv:30,emoji:"🧊",name:"Frost Sovereign",boost:1.85}],
  drakon:  [{lv:15,emoji:"🐉",name:"Drakon Elder",boost:1.4},{lv:30,emoji:"🐲",name:"Dragon God",  boost:1.85}],
};

export const ITEMS = {
  hp_pot:      {id:"hp_pot",      name:"HP Potion",    emoji:"🧪",rarity:"common",   type:"consumable",stats:{hp:60},           price:40,  sell:16,  desc:"Restores 60 HP."},
  mp_pot:      {id:"mp_pot",      name:"Mana Crystal", emoji:"💎",rarity:"common",   type:"consumable",stats:{mp:55},           price:35,  sell:14,  desc:"Restores 55 MP."},
  big_pot:     {id:"big_pot",     name:"Mega Potion",  emoji:"🍶",rarity:"uncommon", type:"consumable",stats:{hp:150},          price:90,  sell:36,  desc:"Restores 150 HP."},
  elixir:      {id:"elixir",      name:"Full Elixir",  emoji:"✨",rarity:"epic",     type:"consumable",stats:{hp:9999,mp:9999}, price:800, sell:320, desc:"Full HP & MP restore."},
  pet_food:    {id:"pet_food",    name:"Pet Treat",    emoji:"🍖",rarity:"common",   type:"consumable",stats:{petHp:40},        price:28,  sell:11,  desc:"Heals your pet 40 HP."},
  shield:      {id:"shield",      name:"Iron Buckler", emoji:"🛡️",rarity:"uncommon", type:"gear",slot:"offhand",stats:{def:12},                price:180, sell:72,  desc:"+12 Defense."},
  blade:       {id:"blade",       name:"Runic Blade",  emoji:"⚔️",rarity:"uncommon", type:"gear",slot:"weapon", stats:{atk:18},                price:240, sell:96,  desc:"+18 Attack."},
  crown:       {id:"crown",       name:"Arcane Crown", emoji:"👑",rarity:"rare",     type:"gear",slot:"head",   stats:{atk:8,def:8,maxHp:40},  price:440, sell:176, desc:"Boosts all stats."},
  amulet:      {id:"amulet",      name:"Soul Amulet",  emoji:"📿",rarity:"rare",     type:"gear",slot:"neck",   stats:{maxMp:60},               price:320, sell:128, desc:"+60 Max Mana."},
  arcane_robe: {id:"arcane_robe", name:"Arcane Robe",  emoji:"🥻",rarity:"rare",     type:"gear",slot:"body",   stats:{def:10,maxMp:40},        price:380, sell:152, desc:"+10 DEF +40 MaxMP."},
  hero_ring:   {id:"hero_ring",   name:"Hero Ring",    emoji:"💍",rarity:"epic",     type:"gear",slot:"ring",   stats:{atk:12,def:6,maxHp:30},  price:600, sell:240, desc:"For true champions."},
  legend_staff:{id:"legend_staff",name:"Legend Staff", emoji:"🪄",rarity:"legendary",type:"gear",slot:"weapon", stats:{atk:30,maxMp:80},        price:1200,sell:480, desc:"Legendary arcane power!"},
};

export const PETS = {
  ignis:  {id:"ignis",  name:"Ignis",  emoji:"🦊",elem:"fire",  hp:70, atk:20,def:6,  color:"#FF8C42",xpReq:0,   lore:"A loyal fire-fox spirit."},
  aqua:   {id:"aqua",   name:"Aqua",   emoji:"🐬",elem:"water", hp:65, atk:16,def:9,  color:"#29B6F6",xpReq:100, lore:"A playful sea dolphin."},
  zapfin: {id:"zapfin", name:"Zapfin", emoji:"🐟",elem:"storm", hp:55, atk:24,def:4,  color:"#FFD600",xpReq:280, lore:"An electric storm fish."},
  frostie:{id:"frostie",name:"Frostie",emoji:"🐺",elem:"ice",   hp:82, atk:22,def:11, color:"#80DEEA",xpReq:950, lore:"A fierce frost wolf."},
  drakon: {id:"drakon", name:"Drakon", emoji:"🐉",elem:"fire",  hp:120,atk:36,def:20, color:"#FF3D00",xpReq:2500,lore:"An ancient dragon guardian."},
};

export const NPCS = {
  witch: {
    name:"Old Witch Mira", emoji:"🧙", portrait:"🧙‍♀️",
    lines:[
      "The dungeon feeds on fear. Charge in headlong!",
      "Your pet grows stronger with every victory.",
      "The Shadowlord was once a great hero…",
      "Answer finance challenges to unlock Critical Hits!",
      "Zone 2 teaches banking. Zone 3 teaches risk & reward.",
      "South is safe. North is glory.",
    ],
  },
  banker: {
    name:"Grand Banker Holt", emoji:"🏦", portrait:"👨‍💼",
    lines:[
      "Interest is the eighth wonder of the world.",
      "Save early, save often. Your future self thanks you.",
      "I = P × r × t. Remember this formula in battle!",
      "Never spend more than you earn — even the Shadowlord learned this too late.",
      "Compound interest grows like a dragon hatching from its egg!",
      "A correct Tier-3 answer grants the Savings Shield buff!",
    ],
  },
};

export const ZONE_REGISTRY = {
  "0_0": {
    name:"Brightfield Town", tier:1,
    sky:"linear-gradient(180deg,#87CEEB 0%,#c8e8ff 42%,#91d158 76%,#5ea332 100%)",
    ambient:["☁️","🌤️","☁️","🌸"],
    bgImage:"linear-gradient(180deg, #87ceeb, #a8d8a8)",
    statics:[
  {id:"shop",   tx:3, ty:2, emoji:"🏪",label:"Shop",        type:"shop",   w:2,h:2},
  {id:"quests", tx:16,ty:2, emoji:"📋",label:"Quests",       type:"quest",  w:1,h:1},
  {id:"library",tx:8, ty:3, emoji:"🏛️",label:"Spell Library",type:"library",w:4,h:3},
  {id:"fountain",tx:10,ty:7,emoji:"⛲",label:"Rest & Heal",  type:"rest",   w:1,h:1},
  {id:"party",  tx:3, ty:9, emoji:"🐾",label:"Party",        type:"party",  w:1,h:1},
  {id:"banker", tx:15,ty:8, emoji:"🏦",label:"Banker Holt",  type:"npc",npcId:"banker",w:2,h:2},
  {id:"d1",tx:1, ty:5,emoji:"🌳",label:"",type:"deco"},
  {id:"d2",tx:18,ty:5,emoji:"🌲",label:"",type:"deco"},
  {id:"d3",tx:6, ty:10,emoji:"🌸",label:"",type:"deco"},
  {id:"d4",tx:14,ty:10,emoji:"🌼",label:"",type:"deco"},
],
    validMonsters:["gloop","puddle","shadowbat","fairy"],
    gates:[
  {tx:9, ty:1, dZx:0,dZy:-1, spawnTx:9, spawnTy:10},
  {tx:10,ty:1, dZx:0,dZy:-1, spawnTx:10,spawnTy:10},
],
  },
  "0_-1": {
    name:"Whispering Woods", tier:2,
    sky:"linear-gradient(180deg,#0e2210 0%,#1e4020 36%,#163a16 72%,#0c2a0c 100%)",
    ambient:["🍂","🍃","🍁","🌙"],
    bgImage:"linear-gradient(180deg,#0e2210,#1e4020)",
    statics:[
      {id:"witch",tx:10,ty:5,emoji:"🧙",label:"Old Witch",  type:"npc",npcId:"witch"},
      {id:"altar",tx:5, ty:8,emoji:"🗿",label:"Stone Altar",type:"rest"},
      {id:"d1",tx:2, ty:2,emoji:"🌲",label:"",type:"deco"},
      {id:"d2",tx:17,ty:2,emoji:"🌲",label:"",type:"deco"},
      {id:"d3",tx:8, ty:4,emoji:"🍄",label:"",type:"deco"},
      {id:"d4",tx:14,ty:9,emoji:"🪨",label:"",type:"deco"},
    ],
    validMonsters:["pyreling","iceling","stormling","siren","leaf_sprite","shadowbat","bouldrox"],
    gates:[
      {tx:9, ty:11,dZx:0,dZy:1, spawnTx:9, spawnTy:1},
      {tx:10,ty:11,dZx:0,dZy:1, spawnTx:10,spawnTy:1},
      {tx:9, ty:0, dZx:0,dZy:-1,spawnTx:9, spawnTy:10},
      {tx:10,ty:0, dZx:0,dZy:-1,spawnTx:10,spawnTy:10},
    ],
  },
  "0_-2": {
    name:"Shadow Dungeon", tier:3,
    sky:"linear-gradient(180deg,#04040c 0%,#080818 50%,#040410 100%)",
    ambient:["💀","🕸️","🦴","💀"],
    bgImage:"linear-gradient(180deg,#04040c,#080818)",
    statics:[
      {id:"boss",  tx:10,ty:1,emoji:"👁️",label:"⚠ BOSS",    type:"monster",enemy:"shadowlord",isBoss:true},
      {id:"altar", tx:10,ty:7,emoji:"⚗️",label:"Dark Altar",type:"rest"},
      {id:"d1",tx:1, ty:1, emoji:"💀",label:"",type:"deco"},
      {id:"d2",tx:18,ty:1, emoji:"💀",label:"",type:"deco"},
      {id:"d3",tx:1, ty:10,emoji:"🕯️",label:"",type:"deco"},
      {id:"d4",tx:18,ty:10,emoji:"🕯️",label:"",type:"deco"},
    ],
    validMonsters:["frostclaw","blazewing","voidshade","stormlord","bouldrox"],
    gates:[
      {tx:9, ty:11,dZx:0,dZy:1,spawnTx:9, spawnTy:1},
      {tx:10,ty:11,dZx:0,dZy:1,spawnTx:10,spawnTy:1},
    ],
  },
};

export function getZoneMeta(zx,zy) {
  const k=`${zx}_${zy}`;
  if(ZONE_REGISTRY[k]) return ZONE_REGISTRY[k];
  const tier=Math.min(3,Math.max(1,Math.abs(zx)+Math.abs(zy)));
  const biomes=[
    {name:`Misty Vale (${zx},${zy})`,  sky:"linear-gradient(180deg,#1a1a2e,#16213e)",  validMonsters:["gloop","shadowbat","fairy","pyreling"]},
    {name:`Wild Reaches (${zx},${zy})`,sky:"linear-gradient(180deg,#2d1b69,#11998e)",  validMonsters:["iceling","siren","stormling"]},
    {name:`Cinder Wastes (${zx},${zy})`,sky:"linear-gradient(180deg,#4a0e0e,#8b0000)", validMonsters:["pyreling","blazewing","bouldrox"]},
  ];
  return {...biomes[Math.abs(zx*7+zy*13)%biomes.length],tier,statics:[],gates:[],ambient:["🌿"],bgImage:"linear-gradient(180deg,#1a1a2e,#16213e)"};
}

export const QUESTS = [
  {id:"q1", name:"First Blood",    emoji:"⚔️",desc:"Win 1 battle.",               goal:{type:"battles",  n:1},    reward:{xp:60,  gold:50}},
  {id:"q2", name:"Spell Slinger",  emoji:"✨",desc:"Cast 10 spells.",             goal:{type:"spells",   n:10},   reward:{xp:120, gold:80}},
  {id:"q3", name:"Loot Hunter",    emoji:"📦",desc:"Open 3 chests.",              goal:{type:"chests",   n:3},    reward:{xp:90,  gold:120}},
  {id:"q4", name:"Monster Mash",   emoji:"👾",desc:"Defeat 10 monsters.",         goal:{type:"battles",  n:10},   reward:{xp:200, gold:150}},
  {id:"q5", name:"Gold Collector", emoji:"💰",desc:"Earn 500 gold total.",        goal:{type:"totalGold",n:500},  reward:{xp:150, gold:200}},
  {id:"q6", name:"Dungeon Delver", emoji:"🗡️",desc:"Reach the Shadow Dungeon.",  goal:{type:"zone",n:1,zx:0,zy:-2},reward:{xp:300,gold:250,spell:"gale"}},
  {id:"q7", name:"Shadow Slayer",  emoji:"👁️",desc:"Defeat the Shadowlord.",     goal:{type:"boss",mId:"shadowlord"},reward:{xp:800,gold:500}},
  {id:"q8", name:"Pet Collector",  emoji:"🐾",desc:"Tame 3 wild monsters.",       goal:{type:"tamed",    n:3},    reward:{xp:250, gold:180}},
  {id:"q9", name:"Finance Master", emoji:"💎",desc:"Answer 20 finance questions.",goal:{type:"financeQ", n:20},   reward:{xp:400, gold:300}},
  {id:"q10",name:"On a Streak",    emoji:"🌟",desc:"Answer 5 in a row correctly.", goal:{type:"streak",   n:5},    reward:{xp:200, gold:150,spell:"nova"}},
];

export const STATUS_EFFECTS = {
  savings_shield:{id:"savings_shield",name:"Savings Shield",emoji:"🛡️",color:"#4CAF50",duration:3,desc:"DEF +10 for 3 turns."},
  financial_debt:{id:"financial_debt",name:"Financial Debt", emoji:"📉",color:"#F44336",duration:2,desc:"ATK halved for 2 turns."},
  lucky_streak:  {id:"lucky_streak",  name:"Lucky Streak",   emoji:"⭐",color:"#FFD700",duration:2,desc:"Crit +15% for 2 turns."},
};

export function scaleMonster(mId,playerLv) {
  const b=BESTIARY[mId]; if(!b) return null;
  const d=Math.max(0,playerLv-b.baseLv); const sf=1+d*.15;
  return { ...b, uuid:makeUUID(),
    currentHp:Math.floor(b.hp*sf*1.2), maxHp:Math.floor(b.hp*sf*1.2),
    scaledAtk:Math.floor(12*b.ak*sf), scaledDef:Math.floor(6*b.dk*sf),
    xpReward:Math.floor(30*b.xk*(1+d*.1)), goldReward:Math.floor(12*b.gk*(1+d*.08)),
    level:Math.max(b.baseLv,playerLv) };
}

export function calcDmg(power,atk,def,ae,de,crit=.08) {
  const base=Math.max(1,power+atk*.28-def*.22);
  const variance=.82+Math.random()*.36;
  const em=elemMult(ae,de);
  const isCrit=Math.random()<crit;
  return { dmg:Math.max(1,Math.floor(base*variance*em*(isCrit?1.75:1))), isCrit, em };
}

export function pickMon(zx,zy,lv) {
  const z=getZoneMeta(zx,zy);
  const valid=(z.validMonsters||[]).filter(id=>{const m=BESTIARY[id];return m&&!m.boss&&Math.abs(m.baseLv-lv)<=4;});
  const pool=valid.length?valid:(z.validMonsters||[]).filter(id=>!BESTIARY[id]?.boss);
  return pool[Math.floor(Math.random()*pool.length)]||"gloop";
}

export function calcCatchRate(enemy,isCorrect) {
  const hpRatio=1-(enemy.currentHp/enemy.maxHp);
  const base=Math.max(0,hpRatio-.5)*2;
  return Math.min(.92,base*(isCorrect?1.6:.4));
}

export function petLevelUp(pet) {
  const xpNeeded=100*pet.level;
  if(pet.xp<xpNeeded) return {pet,evolved:false};
  const nl=pet.level+1;
  const np={...pet,level:nl,xp:pet.xp-xpNeeded,
    maxHp:Math.floor(pet.maxHp*1.06),hp:Math.floor(pet.maxHp*1.06),
    atk:Math.floor(pet.atk*1.06),def:Math.floor(pet.def*1.04)};
  const evo=(PET_EVOLUTIONS[pet.id]||[]).find(e=>e.lv===nl);
  if(evo) return {pet:{...np,emoji:evo.emoji,name:evo.name,
    atk:Math.floor(np.atk*evo.boost),def:Math.floor(np.def*evo.boost),
    maxHp:Math.floor(np.maxHp*evo.boost),hp:Math.floor(np.maxHp*evo.boost)},evolved:true,evolutionData:evo};
  return {pet:np,evolved:false};
}

export function applyLvUp(player,xpGained) {
  let p={...player,levelXp:player.levelXp+xpGained,totalXp:(player.totalXp||0)+xpGained};
  const lvs=[];
  const spellUnlocks={3:["multi_spark","thunder"],4:["blizzard"],5:["tide"],7:["nova","meteor"],8:["grand_heal"],9:["permafrost"],10:["gale"]};
  while(p.level<MAX_LV&&p.levelXp>=xpFor(p.level)) {
    p.levelXp-=xpFor(p.level); p.level++; lvs.push(p.level);
    p.maxHp+=16; p.maxMp+=11; p.baseAtk+=3; p.baseDef+=2;
    p.hp=Math.min(p.maxHp,p.hp+45);
    const unlocks=spellUnlocks[p.level];
    if(unlocks) p.spellsKnown=[...new Set([...p.spellsKnown,...unlocks])];
  }
  return {player:p,lvs};
}

export function generateEntities(zx,zy,playerLv) {
  const rng=mulberry32((zx*73856093^zy*19349663^playerLv*83492791)>>>0);
  const zm=getZoneMeta(zx,zy);
  const tileMap=getZoneTileMap(zx,zy);
  const used=new Set(); const placed=[];
  (zm.statics||[]).forEach(s=>used.add(`${s.tx}_${s.ty}`));
  function tryPlace(type,count,pool) {
    for(let i=0;i<count;i++) {
      for(let att=0;att<80;att++) {
        const tx=1+Math.floor(rng()*(MAP_COLS-2));
        const ty=1+Math.floor(rng()*(MAP_ROWS-2));
        if(!WALKABLE.has(tileMap[ty]?.[tx])) continue;
        const k=`${tx}_${ty}`; if(used.has(k)) continue;
        const nearStatic=(zm.statics||[]).some(s=>Math.abs(s.tx-tx)<=2&&Math.abs(s.ty-ty)<=2);
        if(nearStatic) continue;
        const def=pool[Math.floor(rng()*pool.length)];
        placed.push({uuid:makeUUID(),type,tx,ty,zx,zy,...def,
          isDefeated:false,isLooted:false,
          respawnTicks:type==="MONSTER"?MON_RESPAWN:CHEST_RESPAWN});
        used.add(k); break;
      }
    }
  }
  tryPlace("CHEST",4,[{emoji:"📦",label:"Chest",goldMin:25,goldMax:80}]);
  const monPool=(zm.validMonsters||[]).filter(id=>{const m=BESTIARY[id];return m&&!m.boss&&Math.abs(m.baseLv-playerLv)<=4;})
    .map(id=>({monsterId:id,emoji:BESTIARY[id].emoji,label:BESTIARY[id].name}));
  if(monPool.length) tryPlace("MONSTER",8,monPool);
  return placed;
}

export function tickRespawns(entities) {
  return entities.map(e=>{
    if(!e.isDefeated&&!e.isLooted) return e;
    const t=Math.max(0,(e.respawnTicks||0)-1);
    if(t===0) return {...e,isDefeated:false,isLooted:false,respawnTicks:e.type==="MONSTER"?MON_RESPAWN:CHEST_RESPAWN};
    return {...e,respawnTicks:t};
  });
}

export function createPlayer(name,avatar) {
  return { name,avatar,
    level:1,levelXp:0,totalXp:0,
    hp:100,maxHp:100,mp:80,maxMp:80,
    baseAtk:20,baseDef:10,luck:2,
    gold:300,totalGold:0,battlesWon:0,spellsCast:0,
    zx:0,zy:0,tx:10,ty:6,facing:"RIGHT",
    lastHpRegen:0,lastMpRegen:0,
    inventory:[{uuid:makeUUID(),...ITEMS.hp_pot},{uuid:makeUUID(),...ITEMS.hp_pot},{uuid:makeUUID(),...ITEMS.mp_pot}],
    equippedGear:{},
    party:[{...PETS.ignis,uuid:makeUUID(),hp:PETS.ignis.hp,maxHp:PETS.ignis.hp,level:1,xp:0}],
    activePetId:"ignis",
    unlockedZones:["0_0"],
    spellsKnown:["starbit","chill_splinter","leaf_burst","fireball","tsunami","quake","heal_light"],
    statusEffects:[],
  };
}

export function effStats(p) {
  let ak=0,dk=0,mhp=0,mmp=0;
  Object.values(p.equippedGear).forEach(gid=>{
    const g=ITEMS[gid]; if(!g) return;
    if(g.stats?.atk)   ak+=g.stats.atk;
    if(g.stats?.def)   dk+=g.stats.def;
    if(g.stats?.maxHp) mhp+=g.stats.maxHp;
    if(g.stats?.maxMp) mmp+=g.stats.maxMp;
  });
  (p.statusEffects||[]).forEach(fx=>{
    if(fx.id==="savings_shield") dk+=10;
    if(fx.id==="financial_debt") ak=Math.floor(ak*.5);
  });
  const hasLS=(p.statusEffects||[]).some(fx=>fx.id==="lucky_streak");
  return { effAtk:p.baseAtk+ak, effDef:p.baseDef+dk,
    effMaxHp:p.maxHp+mhp, effMaxMp:p.maxMp+mmp,
    critChance:.08+(p.luck||0)*.01+(hasLS?.15:0) };
}

export function computeProxObj(player,entities,statics,proxDist=1.5) {
  let nearest=null,nd=Infinity;
  for(const o of (statics||[])) {
    if(o.type==="deco") continue;
    const dist=Math.hypot(player.tx-o.tx,player.ty-o.ty);
    if(dist<=proxDist&&dist<nd){nd=dist;nearest={...o,_static:true};}
  }
  for(const e of entities) {
    if(e.isDefeated||e.isLooted) continue;
    const dist=Math.hypot(player.tx-e.tx,player.ty-e.ty);
    if(dist<=proxDist&&dist<nd){nd=dist;nearest=e;}
  }
  return nearest;
}
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 3
// REDUCER — Complete State Machine
// ═══════════════════════════════════════════════════════════════

export const INITIAL_STATE = {
  screen: "PRELOAD",
  overlay: null, overlayData: null,
  _pendingBattle: null,
  player: null, entities: [], proxObj: null,
  tick: 0, toast: null, battle: null,
  isInitialized: false, zoneTransitioning: false,
  questProgress: {}, chestsOpened: 0, tamedCount: 0,
  financeStreakCount: 0, financeStreakBest: 0, totalFinanceAnswered: 0,
  showFinanceModal: false, financeScenario: null,
  pendingSpellCast: null, pendingTame: false,
  screenShake: false,
  // Dialogue state
  activeDialogue: null,
};

// ─── Quest helpers ─────────────────────────────────────────────
function updQBattles(qp,n=1) {
  const o={...qp};
  QUESTS.filter(q=>q.goal.type==="battles").forEach(q=>{
    const cur=Math.min(q.goal.n,(o[q.id]?.progress||0)+n);
    o[q.id]={...o[q.id],progress:cur,done:cur>=q.goal.n};
  }); return o;
}
function updQGold(qp,totalGold) {
  const o={...qp};
  QUESTS.filter(q=>q.goal.type==="totalGold").forEach(q=>{
    const cur=Math.min(q.goal.n,totalGold);
    o[q.id]={...o[q.id],progress:cur,done:cur>=q.goal.n};
  }); return o;
}
function updQSpells(qp,n=1) {
  const o={...qp};
  QUESTS.filter(q=>q.goal.type==="spells").forEach(q=>{
    const cur=Math.min(q.goal.n,(o[q.id]?.progress||0)+n);
    o[q.id]={...o[q.id],progress:cur,done:cur>=q.goal.n};
  }); return o;
}
function updQChests(qp) {
  const o={...qp};
  QUESTS.filter(q=>q.goal.type==="chests").forEach(q=>{
    const cur=Math.min(q.goal.n,(o[q.id]?.progress||0)+1);
    o[q.id]={...o[q.id],progress:cur,done:cur>=q.goal.n};
  }); return o;
}
function applyFx(player,effects=[]) {
  const existing=player.statusEffects||[];
  const merged=[...existing];
  effects.forEach(fx=>{if(!merged.find(e=>e.id===fx.id)) merged.push({...fx,remaining:fx.duration});});
  return {...player,statusEffects:merged};
}
function tickFx(player) {
  const updated=(player.statusEffects||[]).map(fx=>({...fx,remaining:(fx.remaining??fx.duration)-1})).filter(fx=>fx.remaining>0);
  return {...player,statusEffects:updated};
}

// ─── Main Reducer ──────────────────────────────────────────────
function reducer(s,{type,payload}) {
  switch(type) {

  case "PRELOAD_DONE": return {...s,screen:"CREATE"};

  case "INIT_PLAYER": {
    const p=createPlayer(payload.name,payload.avatar);
    const qp={};
    QUESTS.forEach(q=>{qp[q.id]={progress:0,done:false,claimed:false};});
    return {...s,screen:"WORLD",player:p,questProgress:qp,entities:[],isInitialized:false};
  }

  case "INIT_WORLD":
    return {...s,entities:payload.entities,isInitialized:true,zoneTransitioning:false};

  case "TICK": {
    if(!s.player) return s;
    const t=s.tick+1; let p={...s.player};
    const st=effStats(p);
    if(t-p.lastHpRegen>=5&&p.hp<st.effMaxHp)
      p={...p,hp:Math.min(st.effMaxHp,p.hp+1),lastHpRegen:t};
    if(t-p.lastMpRegen>=8&&p.mp<st.effMaxMp)
      p={...p,mp:Math.min(st.effMaxMp,p.mp+2),lastMpRegen:t};
    if(t%3===0&&p.statusEffects?.length) p=tickFx(p);
    const entities=tickRespawns(s.entities);
    const zm=getZoneMeta(p.zx,p.zy);
    const proxObj=computeProxObj(p,entities,zm?.statics||[]);
    return {...s,tick:t,player:p,entities,proxObj,screenShake:false};
  }

  case "MOVE_PLAYER": {
    if(!s.player) return s;
    const {tx,ty}=payload;
    const facing=tx<s.player.tx?"LEFT":tx>s.player.tx?"RIGHT":s.player.facing;
    const zm=getZoneMeta(s.player.zx,s.player.zy);
    const gate=(zm?.gates||[]).find(g=>g.tx===tx&&g.ty===ty);
    if(gate) {
      const nZx=s.player.zx+gate.dZx, nZy=s.player.zy+gate.dZy;
      const newEnts=generateEntities(nZx,nZy,s.player.level);
      const zid=`${nZx}_${nZy}`;
      const uz=[...new Set([...(s.player.unlockedZones||[]),zid])];
      let qp={...s.questProgress};
      QUESTS.filter(q=>q.goal.type==="zone"&&q.goal.zx===nZx&&q.goal.zy===nZy)
        .forEach(q=>{if(!qp[q.id]?.done) qp[q.id]={...qp[q.id],progress:1,done:true};});
      const zoneName=getZoneMeta(nZx,nZy)?.name||`Zone (${nZx},${nZy})`;
      return {...s,
        player:{...s.player,tx:gate.spawnTx,ty:gate.spawnTy,zx:nZx,zy:nZy,facing,unlockedZones:uz},
        entities:newEnts,isInitialized:true,zoneTransitioning:true,
        questProgress:qp,proxObj:null,
        toast:{msg:`🌍 ${zoneName}`,t:"info"}};
    }
    const np={...s.player,tx,ty,facing};
    const proxObj=computeProxObj(np,s.entities,zm?.statics||[]);
    return {...s,player:np,proxObj};
  }

  case "ZONE_DONE": return {...s,zoneTransitioning:false};

  case "LOOT_CHEST": {
    if(!s.player) return s;
    const {uuid}=payload;
    const ent=s.entities.find(e=>e.uuid===uuid&&!e.isLooted);
    if(!ent) return s;
    const gold=Math.floor((ent.goldMin||20)+Math.random()*((ent.goldMax||80)-(ent.goldMin||20)));
    const roll=Math.random();
    const loot=roll<.35?{uuid:makeUUID(),...ITEMS.hp_pot}:roll<.50?{uuid:makeUUID(),...ITEMS.mp_pot}:null;
    let inv=[...s.player.inventory];
    if(loot&&inv.length<30) inv=[...inv,loot];
    const entities=s.entities.map(e=>e.uuid===uuid?{...e,isLooted:true,respawnTicks:CHEST_RESPAWN}:e);
    const totalGold=(s.player.totalGold||0)+gold;
    let qp=updQChests({...s.questProgress});
    qp=updQGold(qp,totalGold);
    return {...s,entities,chestsOpened:(s.chestsOpened||0)+1,questProgress:qp,
      player:{...s.player,gold:s.player.gold+gold,totalGold,inventory:inv},
      toast:{msg:`📦 +${gold}g${loot?" + "+loot.emoji:""}`,t:"gold"}};
  }

  case "START_BATTLE": {
    if(!s.player) return s;
    const {uuid,monsterId,isBoss}=payload;
    const mId=monsterId||pickMon(s.player.zx,s.player.zy,s.player.level);
    const enemy=scaleMonster(mId,s.player.level);
    if(!enemy) return s;
    const entities=uuid?s.entities.map(e=>e.uuid===uuid?{...e,isDefeated:true,respawnTicks:MON_RESPAWN}:e):s.entities;
    return {...s,screen:"TRANSITION_VFX",entities,
      _pendingBattle:{enemy,phase:"SELECT",
        log:[`⚔️ A wild ${enemy.name} appeared!`],
        damageFloats:[],spellMultiplier:1,isCorrectAnswer:false,
        pendingSpellId:null,petAnim:null,petPhase:null}};
  }

  case "TRANSITION_DONE": {
    if(!s._pendingBattle) return {...s,screen:"WORLD"};
    return {...s,screen:"BATTLE",battle:s._pendingBattle,_pendingBattle:null};
  }

  case "PREPARE_CAST": {
    if(!s.battle||!s.player) return s;
    const sp=SPELLS[payload.spellId]; if(!sp) return s;
    if(s.player.mp<sp.mp)
      return {...s,battle:{...s.battle,log:[...s.battle.log,"❌ Not enough MP!"].slice(-12)}};
    const fq=generateFinanceQuestion(s.player.zx,s.player.zy);
    return {...s,battle:{...s.battle,phase:"FINANCE_Q",pendingSpellId:payload.spellId},
      showFinanceModal:true,financeScenario:fq,pendingSpellCast:payload.spellId,pendingTame:false};
  }

  case "ANSWER_FINANCE": {
    if(!s.showFinanceModal||!s.financeScenario) return s;
    const {answer}=payload;
    const isCorrect=String(answer)===String(s.financeScenario.correctAnswer);
    const tier=s.financeScenario.tier||1;
    const bonusMult=isCorrect?(s.financeScenario.bonusMultiplier||1.5):.5;
    const newStreak=isCorrect?(s.financeStreakCount||0)+1:0;
    const bestStreak=Math.max(s.financeStreakBest||0,newStreak);
    const totalQ=(s.totalFinanceAnswered||0)+1;
    let qp={...s.questProgress};
    QUESTS.filter(q=>q.goal.type==="financeQ").forEach(q=>{
      const cur=Math.min(q.goal.n,totalQ); qp[q.id]={...qp[q.id],progress:cur,done:cur>=q.goal.n};});
    QUESTS.filter(q=>q.goal.type==="streak").forEach(q=>{
      const cur=Math.min(q.goal.n,newStreak); qp[q.id]={...qp[q.id],progress:cur,done:cur>=q.goal.n};});
    let player={...s.player};
    if(isCorrect&&tier===3)     player=applyFx(player,[STATUS_EFFECTS.savings_shield]);
    if(!isCorrect&&tier>=2)     player=applyFx(player,[STATUS_EFFECTS.financial_debt]);
    if(isCorrect&&newStreak>=3) player=applyFx(player,[STATUS_EFFECTS.lucky_streak]);
    const sp=SPELLS[s.battle?.pendingSpellId];
    const newMp=sp?Math.max(0,player.mp-sp.mp):player.mp;
    const logMsg=isCorrect?`✨ Correct! ×${bonusMult.toFixed(1)} power!`:`❌ Finance Fumble! ×${bonusMult.toFixed(1)} only`;
    let ns={...s,showFinanceModal:false,financeScenario:null,pendingSpellCast:null,
      financeStreakCount:newStreak,financeStreakBest:bestStreak,
      totalFinanceAnswered:totalQ,questProgress:qp,
      player:{...player,mp:newMp,spellsCast:(player.spellsCast||0)+1}};
    if(!sp) return ns;
    if(sp.isHeal) {
      const st=effStats(ns.player);
      const healed=Math.min(Math.floor(sp.power*bonusMult),st.effMaxHp-ns.player.hp);
      const newHp=Math.min(st.effMaxHp,ns.player.hp+healed);
      const floats=[...ns.battle.damageFloats,{id:makeUUID(),val:healed,x:"22%",y:"38%",isCrit:false,isHeal:true}];
      return {...ns,questProgress:updQSpells(ns.questProgress),
        player:{...ns.player,hp:newHp},
        battle:{...ns.battle,phase:"ENEMY_ATTACK",spellMultiplier:bonusMult,isCorrectAnswer:isCorrect,
          damageFloats:floats,log:[...ns.battle.log,logMsg,`${sp.emoji} +${healed} HP!`].slice(-12)}};
    }
    return {...ns,battle:{...ns.battle,phase:"CAST_CHARGE",
      spellMultiplier:bonusMult,isCorrectAnswer:isCorrect,
      log:[...ns.battle.log,logMsg].slice(-12)}};
  }

  case "CLOSE_FINANCE_MODAL":
    return {...s,showFinanceModal:false,financeScenario:null,pendingSpellCast:null,pendingTame:false,
      battle:s.battle?{...s.battle,phase:"SELECT",pendingSpellId:null}:s.battle};

  case "PHASE_CAST_RELEASE":
    return s.battle?{...s,battle:{...s.battle,phase:"CAST_RELEASE"}}:s;

  case "RESOLVE_SPELL_DAMAGE": {
    if(!s.battle||!s.player) return s;
    const sp=SPELLS[s.battle.pendingSpellId];
    if(!sp) return {...s,battle:{...s.battle,phase:"ENEMY_ATTACK"}};
    const st=effStats(s.player);
    const {dmg,isCrit,em}=calcDmg(sp.power,st.effAtk,s.battle.enemy.scaledDef,sp.elem,s.battle.enemy.elem,st.critChance);
    const finalDmg=Math.max(1,Math.floor(dmg*(s.battle.spellMultiplier||1)));
    const logStr=[`${sp.emoji} ${s.player.name} casts ${sp.name} — ${finalDmg} dmg!`,isCrit?" 💥 CRIT!":"",em>1?" ⭐ Super!":em<1?" 🛡 Resist":""].join("");
    let qp=updQSpells({...s.questProgress});
    const newEHp=s.battle.enemy.currentHp-finalDmg;
    const floats=[...s.battle.damageFloats,{id:makeUUID(),val:finalDmg,x:"62%",y:"20%",isCrit,isHeal:false}];
    if(newEHp<=0) return {...s,questProgress:qp,battle:{...s.battle,phase:"VICTORY",
      enemy:{...s.battle.enemy,currentHp:0},damageFloats:floats,
      log:[...s.battle.log,logStr,`🎉 ${s.battle.enemy.name} defeated!`].slice(-12)}};
    return {...s,questProgress:qp,battle:{...s.battle,phase:"PET_ADVANCE",petAnim:"ADVANCE",
      enemy:{...s.battle.enemy,currentHp:newEHp},damageFloats:floats,
      log:[...s.battle.log,logStr].slice(-12)}};
  }

  case "PHASE_PET_HIT":
    return s.battle?{...s,battle:{...s.battle,phase:"PET_HIT",petAnim:"HIT"}}:s;

  case "RESOLVE_PET_DAMAGE": {
    if(!s.battle||!s.player) return s;
    const petId=s.player.activePetId;
    const petInst=s.player.party?.find(p=>p.id===petId);
    const petBase=PETS[petId]||BESTIARY[petId];
    if(!petInst&&!petBase) return {...s,battle:{...s.battle,phase:"PET_RETREAT",petAnim:"RETREAT"}};
    const pet=petInst||petBase; const mult=s.battle.spellMultiplier||1;
    const {dmg:pd}=calcDmg(pet.atk||15,0,s.battle.enemy.scaledDef,petBase?.elem||"astral",s.battle.enemy.elem,.1);
    const finalPd=Math.max(1,Math.floor(pd*(mult>1?mult*.45:.75)));
    const newEHp=s.battle.enemy.currentHp-finalPd;
    const petLog=`${pet.emoji||"🐾"} ${pet.name} assists — ${finalPd} dmg!`;
    const floats=[...s.battle.damageFloats,{id:makeUUID(),val:finalPd,x:"66%",y:"30%",isCrit:false,isHeal:false}];
    if(newEHp<=0) return {...s,battle:{...s.battle,phase:"VICTORY",petAnim:"RETREAT",
      enemy:{...s.battle.enemy,currentHp:0},damageFloats:floats,
      log:[...s.battle.log,petLog,`🎉 ${s.battle.enemy.name} defeated!`].slice(-12)}};
    return {...s,battle:{...s.battle,phase:"PET_RETREAT",petAnim:"RETREAT",
      enemy:{...s.battle.enemy,currentHp:newEHp},damageFloats:floats,
      log:[...s.battle.log,petLog].slice(-12)}};
  }

  case "PHASE_ENEMY_ATTACK":
    return s.battle?{...s,battle:{...s.battle,phase:"ENEMY_ATTACK",petAnim:null}}:s;

  case "RESOLVE_ENEMY_ATTACK": {
    if(!s.battle||!s.player) return s;
    const st=effStats(s.player);
    const {dmg,isCrit}=calcDmg(s.battle.enemy.scaledAtk,0,st.effDef,s.battle.enemy.elem,"fire",.05);
    const newHp=s.player.hp-dmg;
    const entry=`${s.battle.enemy.emoji} ${s.battle.enemy.name} attacks — ${dmg} dmg!${isCrit?" 💥 CRIT!":""}`;
    const floats=[...s.battle.damageFloats,{id:makeUUID(),val:dmg,x:"18%",y:"32%",isCrit,isHeal:false}];
    if(newHp<=0) return {...s,screenShake:true,player:{...s.player,hp:0},
      battle:{...s.battle,phase:"DEFEAT",damageFloats:floats,
        log:[...s.battle.log,entry,"💀 You were defeated…"].slice(-12)}};
    return {...s,screenShake:true,player:{...s.player,hp:newHp},
      battle:{...s.battle,phase:"SELECT",damageFloats:floats,log:[...s.battle.log,entry].slice(-12)}};
  }

  case "BASIC_ATTACK": {
    if(!s.battle||!s.player) return s;
    const st=effStats(s.player);
    const {dmg,isCrit}=calcDmg(st.effAtk,0,s.battle.enemy.scaledDef,"fire",s.battle.enemy.elem,st.critChance);
    const newEHp=s.battle.enemy.currentHp-dmg;
    const entry=`⚔️ ${s.player.name} attacks — ${dmg} dmg!${isCrit?" 💥 CRIT!":""}`;
    const floats=[...s.battle.damageFloats,{id:makeUUID(),val:dmg,x:"62%",y:"22%",isCrit,isHeal:false}];
    if(newEHp<=0) return {...s,battle:{...s.battle,phase:"VICTORY",
      enemy:{...s.battle.enemy,currentHp:0},damageFloats:floats,
      log:[...s.battle.log,entry,`🎉 ${s.battle.enemy.name} defeated!`].slice(-12)}};
    return {...s,battle:{...s.battle,phase:"PET_ADVANCE",petAnim:"ADVANCE",
      spellMultiplier:isCrit?1.5:1,isCorrectAnswer:isCrit,
      enemy:{...s.battle.enemy,currentHp:newEHp},damageFloats:floats,
      log:[...s.battle.log,entry].slice(-12)}};
  }

  case "PREPARE_TAME": {
    if(!s.battle||!s.player) return s;
    const enemy=s.battle.enemy;
    if(!BESTIARY[enemy.id]?.tameable)
      return {...s,battle:{...s.battle,log:[...s.battle.log,"❌ This creature cannot be tamed!"].slice(-12)}};
    if((enemy.currentHp/enemy.maxHp)>.3)
      return {...s,battle:{...s.battle,log:[...s.battle.log,"❌ Weaken to below 30% HP first!"].slice(-12)}};
    const fq=generateFinanceQuestion(s.player.zx,s.player.zy);
    return {...s,showFinanceModal:true,financeScenario:fq,pendingTame:true,pendingSpellCast:null,
      battle:{...s.battle,phase:"FINANCE_Q"}};
  }

  case "ANSWER_TAME_FINANCE": {
    if(!s.showFinanceModal||!s.pendingTame) return s;
    const {answer}=payload;
    const isCorrect=String(answer)===String(s.financeScenario.correctAnswer);
    const enemy=s.battle.enemy; const base=BESTIARY[enemy.id];
    let ns={...s,showFinanceModal:false,financeScenario:null,pendingTame:false,
      financeStreakCount:isCorrect?(s.financeStreakCount||0)+1:0,
      totalFinanceAnswered:(s.totalFinanceAnswered||0)+1};
    ns.financeStreakBest=Math.max(s.financeStreakBest||0,ns.financeStreakCount);
    const cr=calcCatchRate(enemy,isCorrect);
    const success=Math.random()<cr;
    if(!success) return {...ns,battle:{...ns.battle,phase:"SELECT",
      log:[...ns.battle.log,isCorrect?`❌ Resisted! Catch rate was ${Math.round(cr*100)}%`:"❌ Wrong answer! Tame failed!"].slice(-12)}};
    const newPet={...base,uuid:makeUUID(),
      hp:Math.floor((base.hp||60)*.8),maxHp:Math.floor((base.hp||60)*.8),
      level:enemy.level,xp:0,atk:Math.floor(enemy.scaledAtk*.6),def:Math.floor(enemy.scaledDef*.6)};
    const newParty=[...ns.player.party,newPet].slice(0,6);
    const tc=(ns.tamedCount||0)+1;
    let qp={...ns.questProgress};
    QUESTS.filter(q=>q.goal.type==="tamed").forEach(q=>{
      const cur=Math.min(q.goal.n,tc); qp[q.id]={...qp[q.id],progress:cur,done:cur>=q.goal.n};});
    return {...ns,screen:"WORLD",battle:null,tamedCount:tc,questProgress:qp,
      player:{...ns.player,party:newParty,mp:Math.min(effStats(ns.player).effMaxMp,ns.player.mp+28)},
      toast:{msg:`💖 ${enemy.name} joined your party!`,t:"victory"}};
  }

  case "USE_ITEM_B": {
    if(!s.battle||!s.player) return s;
    const it=s.player.inventory.find(i=>i.uuid===payload.uuid); if(!it) return s;
    const st=effStats(s.player);
    let hp=s.player.hp,mp=s.player.mp; const msgs=[];
    if(it.stats?.hp){hp=Math.min(st.effMaxHp,hp+it.stats.hp);msgs.push(`+${it.stats.hp} HP`);}
    if(it.stats?.mp){mp=Math.min(st.effMaxMp,mp+it.stats.mp);msgs.push(`+${it.stats.mp} MP`);}
    const floats=it.stats?.hp?[...s.battle.damageFloats,{id:makeUUID(),val:it.stats.hp,x:"20%",y:"36%",isCrit:false,isHeal:true}]:s.battle.damageFloats;
    return {...s,player:{...s.player,hp,mp,inventory:s.player.inventory.filter(i=>i.uuid!==payload.uuid)},
      battle:{...s.battle,damageFloats:floats,log:[...s.battle.log,`${it.emoji} ${it.name} — ${msgs.join(", ")}!`].slice(-12)}};
  }

  case "ESCAPE": {
    if(!s.battle||!s.player) return s;
    if(Math.random()<.55) return {...s,screen:"WORLD",battle:null,
      player:{...s.player,mp:Math.min(effStats(s.player).effMaxMp,s.player.mp+28)},
      toast:{msg:"💨 Got away safely!",t:"info"}};
    return {...s,battle:{...s.battle,phase:"ENEMY_ATTACK",
      log:[...s.battle.log,"❌ Couldn't escape! Enemy attacks!"].slice(-12)}};
  }

  case "RETURN_WORLD": {
    if(!s.player||!s.battle) return s;
    const enemy=s.battle.enemy; const isVic=s.battle.phase==="VICTORY";
    let p={...s.player}; let qp={...s.questProgress};
    const postMp=Math.min(effStats(p).effMaxMp,p.mp+28);
    if(isVic) {
      const {player:pp,lvs}=applyLvUp(p,enemy.xpReward);
      let party=[...pp.party]; let evoMsg="";
      if(pp.activePetId) {
        const idx=party.findIndex(pt=>pt.id===pp.activePetId);
        if(idx>=0) {
          const updPet={...party[idx],xp:(party[idx].xp||0)+Math.floor(enemy.xpReward*.5)};
          const {pet:evoPet,evolved}=petLevelUp(updPet);
          party[idx]=evoPet;
          if(evolved) evoMsg=` 🌟 ${evoPet.name} EVOLVED!`;
        }
      }
      p={...pp,party,gold:p.gold+enemy.goldReward,totalGold:(p.totalGold||0)+enemy.goldReward,
        battlesWon:(p.battlesWon||0)+1,mp:postMp};
      const drops=[];
      (enemy.drops||[]).forEach(d=>{
        if(Math.random()<d.ch&&p.inventory.length<30){const it=ITEMS[d.id];if(it) drops.push({uuid:makeUUID(),...it});}});
      if(drops.length) p={...p,inventory:[...p.inventory,...drops]};
      qp=updQBattles(qp); qp=updQGold(qp,p.totalGold);
      if(enemy.boss) QUESTS.filter(q=>q.goal.type==="boss"&&q.goal.mId===enemy.id)
        .forEach(q=>{qp[q.id]={...qp[q.id],progress:1,done:true};});
      const lvMsg=lvs.length?`  🆙 Lv.${p.level}!`:"";
      const dropMsg=drops.length?" | "+drops.map(d=>d.emoji).join(""):"";
      return {...s,screen:"WORLD",battle:null,player:p,questProgress:qp,
        toast:{msg:`🏆 +${enemy.xpReward}xp +${enemy.goldReward}g${dropMsg}${lvMsg}${evoMsg}`,t:"victory"}};
    }
    const st=effStats(p);
    p={...p,hp:Math.floor(st.effMaxHp*.3),mp:postMp,gold:Math.max(0,p.gold-10)};
    return {...s,screen:"WORLD",battle:null,player:p,questProgress:qp,
      toast:{msg:"💀 Defeated… −10g penalty",t:"error"}};
  }

  case "REMOVE_DAMAGE_FLOAT":
    return s.battle?{...s,battle:{...s.battle,damageFloats:s.battle.damageFloats.filter(f=>f.id!==payload.id)}}:s;

  case "CLEAR_SHAKE": return {...s,screenShake:false};

  case "USE_ITEM": {
    if(!s.player) return s;
    const it=s.player.inventory.find(i=>i.uuid===payload.uuid); if(!it) return s;
    const st=effStats(s.player); let p={...s.player}; const msgs=[];
    if(it.stats?.hp){p={...p,hp:Math.min(st.effMaxHp,p.hp+it.stats.hp)};msgs.push(`+${it.stats.hp} HP`);}
    if(it.stats?.mp){p={...p,mp:Math.min(st.effMaxMp,p.mp+it.stats.mp)};msgs.push(`+${it.stats.mp} MP`);}
    p={...p,inventory:p.inventory.filter(i=>i.uuid!==payload.uuid)};
    return {...s,player:p,toast:{msg:`${it.emoji} ${msgs.join(", ")}`,t:"heal"}};
  }

  case "FULL_HEAL": {
    if(!s.player) return s;
    const st=effStats(s.player);
    return {...s,player:{...s.player,hp:st.effMaxHp,mp:st.effMaxMp}};
  }

  case "EQUIP_GEAR": {
    if(!s.player) return s;
    const it=ITEMS[payload.itemId]; if(!it||it.type!=="gear") return s;
    return {...s,player:{...s.player,equippedGear:{...s.player.equippedGear,[it.slot]:payload.itemId}},
      toast:{msg:`${it.emoji} ${it.name} equipped!`,t:"info"}};
  }

  case "UNEQUIP_GEAR": {
    if(!s.player) return s;
    const gear={...s.player.equippedGear}; delete gear[payload.slot];
    return {...s,player:{...s.player,equippedGear:gear}};
  }

  case "BUY_ITEM": {
    if(!s.player) return s;
    const it=ITEMS[payload.itemId]; if(!it) return s;
    if(s.player.gold<it.price) return {...s,toast:{msg:"💸 Not enough gold!",t:"error"}};
    if(s.player.inventory.length>=30) return {...s,toast:{msg:"🎒 Bag full!",t:"error"}};
    return {...s,player:{...s.player,gold:s.player.gold-it.price,
      inventory:[...s.player.inventory,{uuid:makeUUID(),...it}]},
      toast:{msg:`${it.emoji} Purchased!`,t:"gold"}};
  }

  case "SELL_ITEM": {
    if(!s.player) return s;
    const it=s.player.inventory.find(i=>i.uuid===payload.uuid); if(!it) return s;
    const sell=Math.floor((it.price||10)*.4);
    return {...s,player:{...s.player,gold:s.player.gold+sell,
      inventory:s.player.inventory.filter(i=>i.uuid!==payload.uuid)},
      toast:{msg:`${it.emoji} Sold for ${sell}g`,t:"gold"}};
  }

  case "SET_ACTIVE_PET":
    if(!s.player) return s;
    return {...s,player:{...s.player,activePetId:payload.petId}};

  case "CLAIM_QUEST_REWARD": {
    if(!s.player) return s;
    const q=QUESTS.find(q=>q.id===payload.questId); if(!q) return s;
    const qState=s.questProgress[q.id];
    if(!qState?.done||qState?.claimed) return s;
    const {player:pp,lvs}=applyLvUp(s.player,q.reward.xp||0);
    let np={...pp,gold:pp.gold+(q.reward.gold||0)};
    if(q.reward.spell&&!np.spellsKnown.includes(q.reward.spell))
      np={...np,spellsKnown:[...np.spellsKnown,q.reward.spell]};
    const qp={...s.questProgress,[q.id]:{...qState,claimed:true}};
    const lvMsg=lvs.length?`  🆙 Lv.${np.level}!`:"";
    return {...s,player:np,questProgress:qp,
      toast:{msg:`${q.emoji} +${q.reward.xp}xp +${q.reward.gold}g${q.reward.spell?" ✨ Spell!":""}${lvMsg}`,t:"victory"}};
  }

  case "OPEN_DIALOGUE":
    return {...s,activeDialogue:payload};

  case "CLOSE_DIALOGUE":
    return {...s,activeDialogue:null};

  case "ROAM_MONSTER": {
    const {uuid,tx,ty}=payload;
    return {...s,entities:s.entities.map(e=>e.uuid===uuid?{...e,tx,ty}:e)};
  }

  case "SET_OVERLAY":  return {...s,overlay:payload.id,overlayData:payload.data||null};
  case "CLOSE_OVERLAY": return {...s,overlay:null,overlayData:null};
  case "SET_TOAST":    return {...s,toast:payload};
  case "CLR_TOAST":    return {...s,toast:null};

  default: return s;
  }
}
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — NEW BLOCK 4
// HOOKS · ATOMS · HUD · WORLDMAP
// Fixes: multi-tile buildings, building collision, smooth lerp,
//        proximity-only interaction, glowing gate portals
// ═══════════════════════════════════════════════════════════════

export function useWindowDimensions() {
  const [dims,setDims]=useState({w:window.innerWidth,h:window.innerHeight});
  useEffect(()=>{
    const h=()=>setDims({w:window.innerWidth,h:window.innerHeight});
    window.addEventListener("resize",h);
    return()=>window.removeEventListener("resize",h);
  },[]);
  return dims;
}

export function useCountUp(target,duration=600) {
  const [display,setDisplay]=useState(target);
  const prevRef=useRef(target); const rafRef=useRef(null);
  useEffect(()=>{
    const from=prevRef.current; const diff=target-from;
    if(diff===0) return;
    const start=performance.now();
    const animate=ts=>{
      const p=Math.min(1,(ts-start)/duration);
      const e=1-Math.pow(1-p,3);
      setDisplay(Math.round(from+diff*e));
      if(p<1) rafRef.current=requestAnimationFrame(animate);
      else prevRef.current=target;
    };
    cancelAnimationFrame(rafRef.current);
    rafRef.current=requestAnimationFrame(animate);
    return()=>cancelAnimationFrame(rafRef.current);
  },[target,duration]);
  return display;
}

export function useSmoothCamera(playerPx,playerPy,mapW,mapH,viewW,viewH) {
  const targetX=Math.max(0,Math.min(mapW-viewW,playerPx-viewW/2));
  const targetY=Math.max(0,Math.min(mapH-viewH,playerPy-viewH/2));
  const camRef=useRef({x:targetX,y:targetY});
  const [cam,setCam]=useState({x:targetX,y:targetY});
  const rafRef=useRef(null);
  useEffect(()=>{
    const animate=()=>{
      const cx=camRef.current.x+(targetX-camRef.current.x)*0.1;
      const cy=camRef.current.y+(targetY-camRef.current.y)*0.1;
      if(Math.abs(cx-targetX)<0.4&&Math.abs(cy-targetY)<0.4){
        camRef.current={x:targetX,y:targetY}; setCam({x:targetX,y:targetY}); return;
      }
      camRef.current={x:cx,y:cy}; setCam({x:cx,y:cy});
      rafRef.current=requestAnimationFrame(animate);
    };
    cancelAnimationFrame(rafRef.current);
    rafRef.current=requestAnimationFrame(animate);
    return()=>cancelAnimationFrame(rafRef.current);
  },[targetX,targetY]);
  return cam;
}

export function useTileMovement(player,dispatch,walkableFn) {
  const pathRef=useRef([]); const rafRef=useRef(null);
  const [moving,setMoving]=useState(false);
  const [pixelPos,setPixelPos]=useState({x:player.tx,y:player.ty});
  const pixelRef=useRef({x:player.tx,y:player.ty});

  const lerpToTile=useCallback((tx,ty,onDone)=>{
    const startX=pixelRef.current.x; const startY=pixelRef.current.y;
    const startT=performance.now(); const STEP_MS=140;
    const tick=now=>{
      const t=Math.min(1,(now-startT)/STEP_MS);
      const ease=1-Math.pow(1-t,2.4);
      const nx=startX+(tx-startX)*ease; const ny=startY+(ty-startY)*ease;
      pixelRef.current={x:nx,y:ny}; setPixelPos({x:nx,y:ny});
      if(t<1) rafRef.current=requestAnimationFrame(tick);
      else { pixelRef.current={x:tx,y:ty}; setPixelPos({x:tx,y:ty}); onDone(); }
    };
    cancelAnimationFrame(rafRef.current);
    rafRef.current=requestAnimationFrame(tick);
  },[]);

  const walkPath=useCallback(waypoints=>{
    cancelAnimationFrame(rafRef.current);
    pathRef.current=[...waypoints];
    if(!pathRef.current.length){setMoving(false);return;}
    setMoving(true);
    const step=()=>{
      if(!pathRef.current.length){setMoving(false);return;}
      const [tx,ty]=pathRef.current.shift();
      dispatch({type:"MOVE_PLAYER",payload:{tx,ty}});
      lerpToTile(tx,ty,()=>{ if(pathRef.current.length) step(); else setMoving(false); });
    };
    step();
  },[dispatch,lerpToTile]);

  const stopMovement=useCallback(()=>{
    cancelAnimationFrame(rafRef.current);
    pathRef.current=[]; setMoving(false);
  },[]);

  useEffect(()=>{
    pixelRef.current={x:player.tx,y:player.ty};
    setPixelPos({x:player.tx,y:player.ty});
  },[player.zx,player.zy]);

  useEffect(()=>()=>cancelAnimationFrame(rafRef.current),[]);
  return {walkPath,stopMovement,moving,pixelPos};
}

function useRoamingAI(entities,walkableFn,dispatch) {
  const timerRef=useRef({});
  useEffect(()=>{
    const active=entities.filter(e=>e.type==="MONSTER"&&!e.isDefeated);
    const activeIds=new Set(active.map(e=>e.uuid));
    Object.keys(timerRef.current).forEach(id=>{
      if(!activeIds.has(id)){clearTimeout(timerRef.current[id]);delete timerRef.current[id];}
    });
    active.forEach(e=>{
      if(timerRef.current[e.uuid]) return;
      const delay=1800+Math.random()*2400;
      timerRef.current[e.uuid]=setTimeout(()=>{
        delete timerRef.current[e.uuid];
        const dirs=[[-1,0],[1,0],[0,-1],[0,1]].sort(()=>Math.random()-.5);
        for(const [dx,dy] of dirs){
          const nx=e.tx+dx,ny=e.ty+dy;
          if(walkableFn(nx,ny)){ dispatch({type:"ROAM_MONSTER",payload:{uuid:e.uuid,tx:nx,ty:ny}}); break; }
        }
      },delay);
    });
    return()=>{Object.values(timerRef.current).forEach(clearTimeout);timerRef.current={};};
  },[entities,walkableFn,dispatch]);
}

// ═══════════════════════════════════════════════════════════════
// UI ATOMS
// ═══════════════════════════════════════════════════════════════
export const StatBar=({val,max,color,h=10,animate=true})=>{
  const pct=Math.max(0,Math.min(100,(val/Math.max(1,max))*100));
  const c=color||(pct>60?"#4CAF50":pct>30?"#FF9800":"#F44336");
  return(
    <div className="sbt" style={{height:h}}>
      <div className="sbf" style={{width:`${pct}%`,background:c,transition:animate?"width .55s cubic-bezier(.4,0,.2,1)":"none"}}/>
    </div>
  );
};

export const Badge=({label,color="#aaa",bg="transparent",size=9})=>(
  <span style={{padding:"2px 8px",borderRadius:999,background:bg,
    border:`1px solid ${color}55`,color,fontSize:size,
    fontFamily:T.fontB,fontWeight:700,display:"inline-block"}}>
    {label}
  </span>
);

export const GBtn=({children,onClick,disabled,size="md",bg,color="#fff",style={}})=>{
  const sz={sm:{padding:"7px 14px",fontSize:12},md:{padding:"10px 20px",fontSize:14},lg:{padding:"14px 30px",fontSize:17}};
  return(
    <button className="gbtn hud-interactive" onClick={onClick} disabled={!!disabled}
      style={{...sz[size],borderRadius:16,
        background:bg||"rgba(255,255,255,.1)",color,
        border:"1.5px solid rgba(255,255,255,.14)",
        backdropFilter:"blur(10px)",...style}}>
      {children}
    </button>
  );
};

export const DmgFloat=({val,isHeal,isCrit,x,y,onDone})=>{
  useEffect(()=>{const t=setTimeout(onDone,1250);return()=>clearTimeout(t);},[onDone]);
  if(isHeal) return <div className="dmg-heal" style={{left:x,top:y,color:T.greenL,fontSize:22}}>+{val} ✦</div>;
  if(isCrit) return <div className="dmg-crit" style={{left:x,top:y,color:T.gold,fontSize:30}}>💥 {val}!</div>;
  return <div className="dmg-norm" style={{left:x,top:y,color:"#FF6B6B",fontSize:20}}>-{val}</div>;
};

export const ToastBanner=({msg,t})=>{
  const cols={info:"#29B6F6",gold:T.gold,victory:T.greenL,error:"#EF5350",heal:T.greenL};
  const c=cols[t]||"#fff";
  return(
    <div style={{position:"fixed",top:22,left:"50%",transform:"translateX(-50%)",
      background:"rgba(8,5,20,.97)",border:`2px solid ${c}`,
      borderRadius:28,padding:"10px 26px",color:c,
      fontFamily:T.fontD,fontSize:15,zIndex:99999,
      boxShadow:`0 0 32px ${c}44`,animation:"slideDown .3s ease",
      maxWidth:"88vw",textAlign:"center",pointerEvents:"none",
      backdropFilter:"blur(16px)"}}>
      {msg}
    </div>
  );
};

export const StatusBadges=({effects=[]})=>{
  if(!effects.length) return null;
  return(
    <div style={{display:"flex",gap:4,flexWrap:"wrap",marginTop:4}}>
      {effects.map(fx=>(
        <div key={fx.id} style={{background:`${fx.color}22`,border:`1px solid ${fx.color}66`,
          borderRadius:8,padding:"2px 6px",display:"flex",alignItems:"center",gap:3,
          animation:"statusPop .3s ease"}}>
          <span style={{fontSize:10}}>{fx.emoji}</span>
          <span style={{color:fx.color,fontSize:8,fontFamily:T.fontB}}>{fx.name} ×{fx.remaining}</span>
        </div>
      ))}
    </div>
  );
};

export const RarityCard=({rarity,children,style={}})=>{
  const shimmerClass=rarity==="legendary"?"rarity-legendary":rarity==="epic"?"rarity-epic":"";
  const rc=RC[rarity]||RC.common;
  return(
    <div className={shimmerClass} style={{background:"rgba(255,255,255,.04)",
      border:`1px solid ${rc.color}44`,borderRadius:16,
      boxShadow:rarity!=="common"?`0 0 12px ${rc.glow}`:"none",...style}}>
      {children}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// GHOST HUD
// ═══════════════════════════════════════════════════════════════
export const HUD=memo(({player,stats,activePet,dispatch,financeStreak,totalAnswered})=>{
  if(!player) return null;
  const goldDisplay=useCountUp(player.gold);
  const hpPct=((player.hp/stats.effMaxHp)*100).toFixed(0);
  const mpPct=((player.mp/stats.effMaxMp)*100).toFixed(0);
  const xpPct=Math.min(100,(player.levelXp/xpFor(player.level))*100).toFixed(0);
  return(
    <div className="hud-layer" style={{zIndex:8000}}>
      {/* TOP-LEFT: Player Card */}
      <div className="hud-interactive" style={{
        position:"absolute",top:12,left:14,
        background:"rgba(6,4,18,.92)",borderRadius:20,
        padding:"10px 14px",backdropFilter:"blur(18px)",
        border:"2px solid rgba(255,215,0,.22)",
        boxShadow:"0 4px 32px rgba(0,0,0,.6),inset 0 1px 0 rgba(255,255,255,.06)",
        minWidth:220,maxWidth:260}}>
        <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:8}}>
          <div style={{position:"relative"}}>
            <span style={{fontSize:32,display:"block",animation:"bobPet 3s ease-in-out infinite",
              filter:"drop-shadow(0 0 12px rgba(255,215,0,.4))"}}>{player.avatar}</span>
            <div style={{position:"absolute",bottom:-2,right:-2,
              background:T.purple,borderRadius:"50%",width:14,height:14,
              display:"flex",alignItems:"center",justifyContent:"center",
              fontSize:7,fontFamily:T.fontD,color:"#fff",border:"1px solid rgba(255,255,255,.2)"}}>
              {player.level}
            </div>
          </div>
          <div style={{flex:1}}>
            <div style={{fontFamily:T.fontD,color:T.gold,fontSize:15,lineHeight:1,
              textShadow:`0 0 12px ${T.goldGlow}`}}>{player.name}</div>
            <div style={{display:"flex",gap:5,marginTop:4,flexWrap:"wrap"}}>
              <Badge label={`Lv.${player.level}`} color={T.gold} bg={`${T.gold}22`}/>
              <Badge label={`${goldDisplay}g`} color="#FFD700" bg="rgba(255,215,0,.1)"/>
            </div>
          </div>
        </div>
        <div style={{marginBottom:5}}>
          <div style={{display:"flex",justifyContent:"space-between",fontSize:9,color:"#EF5350",marginBottom:2}}>
            <span style={{fontFamily:T.fontB,fontWeight:700}}>❤ HP {hpPct}%</span>
            <span style={{fontFamily:T.fontB}}>{player.hp}/{stats.effMaxHp}</span>
          </div>
          <StatBar val={player.hp} max={stats.effMaxHp} color="#EF5350" h={9}/>
        </div>
        <div style={{marginBottom:5}}>
          <div style={{display:"flex",justifyContent:"space-between",fontSize:9,color:"#42A5F5",marginBottom:2}}>
            <span style={{fontFamily:T.fontB,fontWeight:700}}>💧 MP {mpPct}%</span>
            <span style={{fontFamily:T.fontB}}>{player.mp}/{stats.effMaxMp}</span>
          </div>
          <StatBar val={player.mp} max={stats.effMaxMp} color="#42A5F5" h={9}/>
        </div>
        <div>
          <div style={{display:"flex",justifyContent:"space-between",fontSize:9,color:T.gold,marginBottom:2}}>
            <span style={{fontFamily:T.fontB,fontWeight:700}}>✨ XP {xpPct}%</span>
            <span style={{fontFamily:T.fontB}}>{player.levelXp}/{xpFor(player.level)}</span>
          </div>
          <StatBar val={player.levelXp} max={xpFor(player.level)} color={T.gold} h={6}/>
        </div>
        <StatusBadges effects={player.statusEffects||[]}/>
      </div>

      {/* TOP-RIGHT: Active Pet */}
      {activePet&&(
        <div className="hud-interactive" style={{
          position:"absolute",top:12,right:14,
          background:"rgba(6,4,18,.92)",borderRadius:20,
          padding:"8px 12px",backdropFilter:"blur(18px)",
          border:`2px solid ${activePet.color||T.purple}44`,
          boxShadow:`0 4px 24px rgba(0,0,0,.5),0 0 16px ${activePet.color||T.purple}22`,
          minWidth:130,maxWidth:160}}>
          <div style={{display:"flex",alignItems:"center",gap:8}}>
            <span style={{fontSize:26,animation:"bobPet 2.2s ease-in-out infinite",
              filter:`drop-shadow(0 0 8px ${activePet.color||T.purple}88)`}}>
              {activePet.emoji}
            </span>
            <div style={{flex:1}}>
              <div style={{color:activePet.color||T.purple,fontSize:11,fontFamily:T.fontD,lineHeight:1}}>
                {activePet.name}
              </div>
              <div style={{color:"#666",fontSize:8,fontFamily:T.fontB,marginBottom:4}}>Lv.{activePet.level}</div>
              <StatBar val={activePet.hp} max={activePet.maxHp} color={activePet.color||T.purple} h={5}/>
              <div style={{marginTop:2}}>
                <StatBar val={activePet.xp||0} max={100*activePet.level} color="#FFD600" h={3}/>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* BOTTOM-LEFT: Menu buttons */}
      <div className="hud-interactive" style={{
        position:"absolute",bottom:14,left:14,
        display:"flex",gap:6,flexWrap:"wrap",maxWidth:360}}>
        {[
          {id:"inventory",emoji:"🎒",label:"Bag",   color:"#78909C"},
          {id:"shop",     emoji:"🏪",label:"Shop",  color:T.gold},
          {id:"party",    emoji:"🐾",label:"Party", color:T.purple},
          {id:"library",  emoji:"📚",label:"Spells",color:"#42A5F5"},
          {id:"quests",   emoji:"📋",label:"Quests",color:T.green},
        ].map(({id,emoji,label,color})=>(
          <button key={id} className="gbtn hud-interactive"
            onClick={()=>dispatch({type:"SET_OVERLAY",payload:{id}})}
            style={{background:"rgba(6,4,18,.92)",border:`1.5px solid ${color}44`,
              borderRadius:14,padding:"7px 11px",
              display:"flex",flexDirection:"column",alignItems:"center",gap:2,
              backdropFilter:"blur(14px)",minWidth:52,
              boxShadow:`0 4px 16px rgba(0,0,0,.5),0 0 8px ${color}22`,
              cursor:"pointer",pointerEvents:"auto"}}>
            <span style={{fontSize:18}}>{emoji}</span>
            <span style={{color,fontSize:8,fontFamily:T.fontB,fontWeight:700}}>{label}</span>
          </button>
        ))}
      </div>

      {/* BOTTOM-RIGHT: Finance streak */}
      {totalAnswered>0&&(
        <div style={{position:"absolute",bottom:14,right:14,
          background:"rgba(6,4,18,.9)",borderRadius:14,padding:"6px 12px",
          backdropFilter:"blur(12px)",border:"1.5px solid rgba(255,215,0,.2)",
          display:"flex",gap:10,alignItems:"center",pointerEvents:"none"}}>
          {financeStreak>=2&&(
            <div style={{fontFamily:T.fontD,color:T.greenL,fontSize:11}}>🔥 ×{financeStreak}</div>
          )}
          <div style={{fontFamily:T.fontB,color:"#666",fontSize:9}}>{totalAnswered} answered</div>
        </div>
      )}
    </div>
  );
});

// ═══════════════════════════════════════════════════════════════
// WORLDMAP — Multi-tile buildings, proximity interaction, smooth lerp
// ═══════════════════════════════════════════════════════════════
export const WorldMap=memo(({state,dispatch})=>{
  const {player,entities,proxObj,zoneTransitioning}=state;
  const {w:winW,h:winH}=useWindowDimensions();
  if(!player) return null;

  const zm=getZoneMeta(player.zx,player.zy)||{};
  const tileMap=getZoneTileMap(player.zx,player.zy);
  const statics=zm.statics||[];

  const tSz=Math.max(36,Math.ceil(Math.max(winW/MAP_COLS,winH/MAP_ROWS)));
  const mapW=tSz*MAP_COLS;
  const mapH=tSz*MAP_ROWS;

  // ─── Building footprint: blocks tiles occupied by large buildings ──
  const buildingFootprint=useMemo(()=>{
    const blocked=new Set();
    statics.forEach(s=>{
      if(s.type==="deco") return;
      const w=s.w||1, h=s.h||1;
      if(w===1&&h===1) return;
      // Block all tiles EXCEPT bottom-center row (the "door" approach tiles)
      for(let dy=0;dy<h;dy++){
        for(let dx=0;dx<w;dx++){
          // Leave the bottom row unblocked as entrance
          if(dy<h-1) blocked.add(`${s.tx+dx}_${s.ty+dy}`);
        }
      }
    });
    return blocked;
  },[statics]);

  // ─── Combined walkability: tile + building footprint ───────────
  const isWalkableAdv=useCallback((tx,ty)=>{
    if(!isTileWalkable(tileMap,tx,ty)) return false;
    if(buildingFootprint.has(`${tx}_${ty}`)) return false;
    return true;
  },[tileMap,buildingFootprint]);

  const {walkPath,stopMovement,moving,pixelPos}=useTileMovement(player,dispatch,isWalkableAdv);
  useRoamingAI(entities,isWalkableAdv,dispatch);

  const playerPx=(pixelPos.x+0.5)*tSz;
  const playerPy=(pixelPos.y+0.5)*tSz;
  const cam=useSmoothCamera(playerPx,playerPy,mapW,mapH,winW,winH);

  const t2s=(tx,ty)=>({x:tx*tSz+tSz/2-cam.x, y:ty*tSz+tSz/2-cam.y});
  const pcx=playerPx-cam.x;
  const pcy=playerPy-cam.y;

  // Keyboard movement
  useEffect(()=>{
    const handler=e=>{
      if(!["ArrowUp","ArrowDown","ArrowLeft","ArrowRight","w","a","s","d"].includes(e.key)) return;
      e.preventDefault(); stopMovement();
      const dx=(e.key==="ArrowRight"||e.key==="d")?1:(e.key==="ArrowLeft"||e.key==="a")?-1:0;
      const dy=(e.key==="ArrowDown"||e.key==="s")?1:(e.key==="ArrowUp"||e.key==="w")?-1:0;
      const nx=player.tx+dx,ny=player.ty+dy;
      if(isWalkableAdv(nx,ny)) dispatch({type:"MOVE_PLAYER",payload:{tx:nx,ty:ny}});
    };
    window.addEventListener("keydown",handler);
    return()=>window.removeEventListener("keydown",handler);
  },[player.tx,player.ty,isWalkableAdv,dispatch,stopMovement]);

  // Click-to-move
  const handleMapClick=useCallback(e=>{
    if(e.target.closest(".hud-interactive")||e.target.closest(".gbtn")) return;
    const rect=e.currentTarget.getBoundingClientRect();
    const tx=Math.floor((e.clientX-rect.left+cam.x)/tSz);
    const ty=Math.floor((e.clientY-rect.top+cam.y)/tSz);
    if(!isWalkableAdv(tx,ty)) return;
    stopMovement();
    const path=aStarTile(player.tx,player.ty,tx,ty,isWalkableAdv);
    walkPath(path);
  },[cam,tSz,isWalkableAdv,player.tx,player.ty,walkPath,stopMovement]);

  const handleInteract=useCallback(()=>{
    if(!proxObj) return;
    if(proxObj._static){
      const t=proxObj.type;
      if(t==="shop")    dispatch({type:"SET_OVERLAY",payload:{id:"shop"}});
      if(t==="quest")   dispatch({type:"SET_OVERLAY",payload:{id:"quests"}});
      if(t==="library") dispatch({type:"SET_OVERLAY",payload:{id:"library"}});
      if(t==="party")   dispatch({type:"SET_OVERLAY",payload:{id:"party"}});
      if(t==="npc")     dispatch({type:"OPEN_DIALOGUE",payload:{npcId:proxObj.npcId}});
      if(t==="rest"){dispatch({type:"FULL_HEAL"});dispatch({type:"SET_TOAST",payload:{msg:"✨ Fully restored!",t:"heal"}});}
      if(t==="monster"&&proxObj.enemy) dispatch({type:"START_BATTLE",payload:{monsterId:proxObj.enemy,isBoss:proxObj.isBoss}});
    } else {
      if(proxObj.type==="CHEST")   dispatch({type:"LOOT_CHEST",payload:{uuid:proxObj.uuid}});
      if(proxObj.type==="MONSTER") dispatch({type:"START_BATTLE",payload:{uuid:proxObj.uuid,monsterId:proxObj.monsterId}});
    }
  },[proxObj,dispatch]);

  const handleEntityTap=useCallback((e,ent)=>{
    e.stopPropagation();
    const dist=Math.hypot(player.tx-ent.tx,player.ty-ent.ty);
    if(dist>1.5){
      const path=aStarTile(player.tx,player.ty,ent.tx,ent.ty,isWalkableAdv);
      if(path.length>1) path.pop();
      if(path.length) walkPath(path);
    } else {
      handleInteract();
    }
  },[player.tx,player.ty,isWalkableAdv,walkPath,handleInteract]);

  // Y-sorted layer: separate large buildings from regular entities
  const {bigBuildings, layer2}=useMemo(()=>{
    const big=[];
    const small=[];
    statics.forEach(o=>{
      const w=o.w||1, h=o.h||1;
      if(o.type!=="deco"&&(w>1||h>1)){
        big.push({...o,_static:true,_big:true});
      } else if(o.type==="deco"){
        small.push({...o,_static:true,_deco:true,_depth:o.ty+0.05});
      } else {
        small.push({...o,_static:true,_depth:o.ty+0.1});
      }
    });
    entities.forEach(e=>{if(!e.isDefeated&&!e.isLooted) small.push({...e,_depth:e.ty+0.2});});
    const petId=player.activePetId;
    if(petId&&PETS[petId]) small.push({_isPet:true,petId,tx:pixelPos.x-0.85,ty:pixelPos.y+0.1,_depth:pixelPos.y+0.44});
    small.push({_isPlayer:true,tx:pixelPos.x,ty:pixelPos.y,_depth:pixelPos.y+0.5});
    return {bigBuildings:big, layer2:small.sort((a,b)=>a._depth-b._depth)};
  },[statics,entities,pixelPos,player.activePetId]);

  const particles=useMemo(()=>Array.from({length:6},(_,i)=>({
    id:i,emoji:(zm.ambient||["🌿"])[i%Math.max(1,(zm.ambient||[]).length)],
    dur:20+i*3.5,delay:i*1.6,top:8+i*14,
  })),[zm.ambient]);

  return(
    <div id="game-container" onClick={handleMapClick}
      className={zoneTransitioning?"zone-enter":""}
      style={{position:"absolute",inset:0,
        background:zm.sky||"linear-gradient(180deg,#1a1a2e,#16213e)",
        overflow:"hidden",cursor:"crosshair",userSelect:"none"}}>

      {/* Ambient particles */}
      {particles.map(p=>(
        <div key={p.id} style={{position:"absolute",top:`${p.top}%`,left:"-8%",
          fontSize:20,opacity:.42,pointerEvents:"none",zIndex:3,
          animation:`cloudDrift ${p.dur}s linear ${p.delay}s infinite`}}>
          {p.emoji}
        </div>
      ))}

      {/* LAYER 1 — GROUND TILES */}
      <div style={{position:"absolute",left:-cam.x,top:-cam.y,
        width:mapW,height:mapH,zIndex:10,pointerEvents:"none"}}>
        {tileMap.map((row,ty)=>row.map((tileId,tx)=>{
          const gfx=TILE_GFX[tileId]||TILE_GFX[0];
          const bg=(tx+ty)%2===0?gfx.bg:gfx.alt;
          const walkable=WALKABLE.has(tileId);
          // Highlight building footprint in debug (remove if unwanted)
          const isBuildingBlocked=buildingFootprint.has(`${tx}_${ty}`);
          return(
            <div key={`${tx}_${ty}`} style={{
              position:"absolute",left:tx*tSz,top:ty*tSz,
              width:tSz,height:tSz,
              background:isBuildingBlocked?"rgba(0,0,0,.35)":bg,
              display:"flex",alignItems:"flex-end",justifyContent:"center",
              fontSize:Math.floor(tSz*.45),lineHeight:1,
              boxShadow:!walkable?"inset 0 -4px 8px rgba(0,0,0,.4)":"none"}}>
              {gfx.emoji&&!gfx.canopy&&<span style={{marginBottom:2,opacity:.85}}>{gfx.emoji}</span>}
              {gfx.canopy&&<span style={{fontSize:Math.floor(tSz*.5),filter:"brightness(.65)"}}>{gfx.emoji||"🟫"}</span>}
            </div>
          );
        }))}
      </div>

      {/* MULTI-TILE BUILDINGS — rendered before Y-sorted entities */}
      {bigBuildings.map(b=>{
        const w=b.w||1, h=b.h||1;
        const bLeft=b.tx*tSz-cam.x;
        const bTop=b.ty*tSz-cam.y;
        const bWidth=w*tSz;
        const bHeight=h*tSz;
        const isProx=proxObj&&proxObj._static&&proxObj.id===b.id;
        const glowColor=b.type==="shop"?T.gold:b.type==="library"?"#42A5F5":b.type==="npc"?T.purple:T.greenL;
        return(
          <div key={b.id} className="map-ent"
            onClick={ev=>{ev.stopPropagation();handleEntityTap(ev,b);}}
            style={{
              position:"absolute",left:bLeft,top:bTop,
              width:bWidth,height:bHeight,
              zIndex:20+Math.floor(b.ty*10),
              display:"flex",flexDirection:"column",
              alignItems:"center",justifyContent:"center",
              background:`radial-gradient(circle at 50% 60%,${glowColor}18 0%,${glowColor}08 50%,transparent 80%)`,
              border:`2px solid ${isProx?glowColor:glowColor+"33"}`,
              borderRadius:Math.floor(tSz*.3),
              backdropFilter:isProx?"blur(4px)":"none",
              boxShadow:isProx?`0 0 32px ${glowColor}66,0 0 64px ${glowColor}33`:
                `0 4px 24px rgba(0,0,0,.5)`,
              transition:"box-shadow .3s ease,border-color .3s ease",
              cursor:"pointer",
            }}>
            {/* Building icon */}
            <span style={{
              fontSize:Math.floor(tSz*Math.min(w,h)*.65),
              filter:`drop-shadow(0 4px 12px rgba(0,0,0,.7)) drop-shadow(0 0 20px ${glowColor}66)`,
              animation:"floatIdle 4s ease-in-out infinite",
              lineHeight:1,
            }}>
              {b.emoji}
            </span>
            {/* Label below icon */}
            {b.label&&(
              <div style={{
                fontFamily:T.fontD,fontSize:Math.max(9,Math.floor(tSz*.2)),
                color:"rgba(255,255,255,.9)",
                background:"rgba(0,0,0,.72)",
                borderRadius:8,padding:"2px 10px",marginTop:4,
                border:`1px solid ${glowColor}44`,
                textShadow:`0 0 8px ${glowColor}`,
              }}>
                {b.label}
              </div>
            )}
            {/* Glow ring when proximate */}
            {isProx&&(
              <div style={{
                position:"absolute",inset:-8,borderRadius:Math.floor(tSz*.4),
                border:`3px solid ${glowColor}`,
                animation:"pulseGold 1.1s ease-in-out infinite",
                pointerEvents:"none",
              }}/>
            )}
          </div>
        );
      })}

      {/* GATE PORTALS — glowing animated */}
      {(zm.gates||[]).map(g=>{
        const gp=t2s(g.tx,g.ty);
        const arrow=g.dZy===-1?"⬆":g.dZy===1?"⬇":g.dZx===1?"➡":"⬅";
        const destMeta=getZoneMeta(player.zx+g.dZx,player.zy+g.dZy);
        const tier=getZoneTier(player.zx+g.dZx,player.zy+g.dZy);
        const portalColor=tier===1?"#4CAF50":tier===2?"#9C27B0":"#F44336";
        return(
          <div key={`gate_${g.tx}_${g.ty}`} style={{
            position:"absolute",left:gp.x,top:gp.y,
            transform:"translate(-50%,-50%)",
            zIndex:22,pointerEvents:"none",
          }}>
            {/* Outer glow ring */}
            <div style={{
              position:"absolute",
              width:tSz*1.6,height:tSz*1.6,
              borderRadius:"50%",
              border:`3px solid ${portalColor}`,
              boxShadow:`0 0 20px ${portalColor}88,0 0 40px ${portalColor}44,inset 0 0 20px ${portalColor}22`,
              animation:"pulseGold 1.4s ease-in-out infinite",
              left:"50%",top:"50%",transform:"translate(-50%,-50%)",
            }}/>
            {/* Arrow */}
            <div style={{
              position:"relative",
              fontSize:Math.floor(tSz*.7),
              animation:"floatIdle 1.6s ease-in-out infinite",
              filter:`drop-shadow(0 0 12px ${portalColor})`,
              zIndex:1,
            }}>
              {arrow}
            </div>
            {/* Zone name tooltip */}
            <div style={{
              position:"absolute",bottom:"110%",left:"50%",
              transform:"translateX(-50%)",
              fontFamily:T.fontD,fontSize:9,color:portalColor,
              background:"rgba(0,0,0,.85)",
              borderRadius:8,padding:"3px 8px",
              border:`1px solid ${portalColor}55`,
              whiteSpace:"nowrap",
              textShadow:`0 0 8px ${portalColor}`,
            }}>
              {destMeta?.name||"Next Zone"}
            </div>
          </div>
        );
      })}

      {/* LAYER 2 — Y-SORTED ENTITIES */}
      {layer2.map((e,i)=>{
        const pos=t2s(e.tx,e.ty);

        if(e._isPlayer){
          return(
            <div key="player" style={{position:"absolute",left:pcx,top:pcy,
              transform:"translate(-50%,-65%)",
              zIndex:30+Math.floor(e._depth*10),pointerEvents:"none"}}>
              <span style={{fontSize:Math.floor(tSz*.88),display:"block",
                transform:player.facing==="LEFT"?"scaleX(-1)":"scaleX(1)",
                animation:moving?"walkBob .34s ease-in-out infinite":"floatIdle 3s ease-in-out infinite",
                filter:"drop-shadow(0 6px 10px rgba(0,0,0,.7)) drop-shadow(0 0 14px rgba(255,215,0,.38))"}}>
                {player.avatar}
              </span>
              <div style={{position:"absolute",bottom:-2,left:"50%",transform:"translateX(-50%)",
                width:tSz*.72,height:tSz*.16,background:"rgba(0,0,0,.45)",
                borderRadius:"50%",filter:"blur(5px)"}}/>
            </div>
          );
        }

        if(e._isPet){
          const base=PETS[e.petId]; if(!base) return null;
          return(
            <div key="pet" style={{position:"absolute",
              left:pcx-tSz*.85,top:pcy+tSz*.06,
              transform:"translate(-50%,-65%)",
              zIndex:30+Math.floor(e._depth*10),pointerEvents:"none"}}>
              <span style={{fontSize:Math.floor(tSz*.6),display:"block",
                transform:player.facing==="LEFT"?"scaleX(-1)":"scaleX(1)",
                animation:moving?"walkBob .38s ease-in-out infinite":"bobPet 2.4s ease-in-out infinite",
                filter:`drop-shadow(0 4px 6px rgba(0,0,0,.55)) drop-shadow(0 0 8px ${base.color}88)`}}>
                {base.emoji}
              </span>
            </div>
          );
        }

        if(e._deco){
          return(
            <div key={e.id} style={{position:"absolute",left:pos.x,top:pos.y,
              transform:"translate(-50%,-50%)",
              zIndex:15+Math.floor(e._depth*10),pointerEvents:"none",
              fontSize:Math.floor(tSz*.68)}}>
              {e.emoji}
            </div>
          );
        }

        const isProx=proxObj&&(proxObj.uuid===e.uuid||(proxObj._static&&proxObj.id===e.id));
        const emojiSz=Math.floor(tSz*.74*(e.sc||1));
        return(
          <div key={e.uuid||e.id} className="map-ent"
            onClick={ev=>handleEntityTap(ev,e)}
            style={{position:"absolute",left:pos.x,top:pos.y,
              transform:"translate(-50%,-65%)",
              zIndex:20+Math.floor(e._depth*10),
              display:"flex",flexDirection:"column",alignItems:"center",
              cursor:"pointer"}}>
            {isProx&&(
              <div style={{position:"absolute",top:"50%",left:"50%",
                transform:"translate(-50%,-50%)",
                width:tSz*1.3,height:tSz*1.3,borderRadius:"50%",
                border:`2.5px solid ${T.gold}`,
                animation:"pulseGold 1.1s ease-in-out infinite",
                pointerEvents:"none",zIndex:-1}}/>
            )}
            <span style={{fontSize:emojiSz,display:"block",lineHeight:1,
              animation:e.type==="MONSTER"?"monWander 2.5s ease-in-out infinite":"floatIdle 3s ease-in-out infinite",
              filter:e.isBoss?`drop-shadow(0 0 12px ${T.red})`:"drop-shadow(0 4px 6px rgba(0,0,0,.55))"}}>
              {e.emoji}
            </span>
            <div style={{width:emojiSz*.7,height:emojiSz*.14,background:"rgba(0,0,0,.38)",
              borderRadius:"50%",filter:"blur(3px)",marginTop:-4}}/>
            {e.label&&(
              <div style={{fontSize:Math.max(7,Math.floor(tSz*.17)),
                color:e.isBoss?T.red:"rgba(255,255,255,.92)",
                background:"rgba(0,0,0,.72)",borderRadius:6,
                padding:"1px 6px",fontFamily:T.fontB,whiteSpace:"nowrap",marginTop:2}}>
                {e.label}
              </div>
            )}
          </div>
        );
      })}

      {/* LAYER 3 — CANOPY */}
      <div style={{position:"absolute",left:-cam.x,top:-cam.y,
        width:mapW,height:mapH,zIndex:65,pointerEvents:"none"}}>
        {tileMap.map((row,ty)=>row.map((tileId,tx)=>{
          const gfx=TILE_GFX[tileId]; if(!gfx?.canopy) return null;
          return(
            <div key={`c_${tx}_${ty}`} style={{
              position:"absolute",left:tx*tSz,top:ty*tSz-tSz*.65,
              width:tSz,height:tSz*1.7,
              display:"flex",alignItems:"flex-start",justifyContent:"center",
              fontSize:Math.floor(tSz*.92),
              filter:"drop-shadow(0 -3px 10px rgba(0,0,0,.45))",
              pointerEvents:"none"}}>
              {gfx.canopy}
            </div>
          );
        }))}
      </div>

      {/* INTERACT BUBBLE — proximity-only, above canopy */}
      {proxObj&&(
        <div style={{position:"absolute",left:pcx,top:pcy-tSz-16,
          transform:"translateX(-50%)",zIndex:9000,animation:"popIn .22s ease",
          pointerEvents:"auto"}}>
          <GBtn onClick={handleInteract} size="sm"
            bg={`linear-gradient(135deg,${T.gold},${T.goldD})`} color="#000"
            style={{fontWeight:700,fontSize:11,padding:"5px 14px",
              boxShadow:`0 0 20px ${T.goldGlow},0 4px 16px rgba(0,0,0,.5)`}}>
            {proxObj.label||proxObj.name||"Interact"} [E]
          </GBtn>
        </div>
      )}

      {/* Zone label */}
      <div style={{position:"absolute",bottom:70,left:"50%",transform:"translateX(-50%)",
        fontFamily:T.fontD,fontSize:13,color:"rgba(255,215,0,.72)",
        pointerEvents:"none",zIndex:70,textShadow:"0 2px 10px #000",letterSpacing:1.5,
        background:"rgba(0,0,0,.38)",padding:"3px 14px",borderRadius:12,
        backdropFilter:"blur(4px)"}}>
        {zm.name||`Zone (${player.zx},${player.zy})`}
        <span style={{color:"rgba(255,255,255,.22)",fontSize:10,marginLeft:10}}>
          [{player.zx},{player.zy}]
        </span>
      </div>
    </div>
  );
});// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — NEW BLOCK 5
// Z-INDEX TIERS:  1=BG  20=Sprites  50=VFX(no clicks)  100=HUD(always clicks)
// ═══════════════════════════════════════════════════════════════

export const TransitionVFX=({onDone})=>{
  const [phase,setPhase]=useState("in");
  useEffect(()=>{
    const t1=setTimeout(()=>setPhase("hold"),200);
    const t2=setTimeout(()=>setPhase("out"),500);
    const t3=setTimeout(onDone,680);
    return()=>{clearTimeout(t1);clearTimeout(t2);clearTimeout(t3);};
  },[onDone]);
  return(
    <div style={{position:"fixed",inset:0,zIndex:99000,
      background:"radial-gradient(circle at 50% 50%,#2a0050 0%,#0a0020 55%,#000 100%)",
      display:"flex",alignItems:"center",justifyContent:"center",
      opacity:phase==="out"?0:1,transition:"opacity .18s ease",pointerEvents:"none"}}>
      <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:16}}>
        <div style={{fontSize:72,animation:"castRelease .4s ease infinite",
          filter:`drop-shadow(0 0 40px ${T.gold})`}}>⚔️</div>
        <div style={{fontFamily:T.fontD,fontSize:32,color:T.gold,letterSpacing:4,
          animation:"glowPulse .5s ease-in-out infinite",
          textShadow:`0 0 40px ${T.gold}`}}>BATTLE!</div>
      </div>
    </div>
  );
};

// ─── Spell impact particles (pointer-events: none) ─────────────
const SpellImpact=({color,count=18,cx,cy})=>{
  const particles=useMemo(()=>Array.from({length:count},(_,i)=>{
    const angle=(i/count)*Math.PI*2, dist=40+Math.random()*60;
    return{id:i,tx:`${Math.cos(angle)*dist}px`,ty:`${Math.sin(angle)*dist}px`,
      delay:i*.025,size:3+Math.random()*7,shape:Math.random()>.5?"50%":"2px"};
  }),[count]);
  return(
    <div style={{position:"absolute",left:cx,top:cy,pointerEvents:"none"}}>
      {particles.map(p=>(
        <div key={p.id} style={{position:"absolute",width:p.size,height:p.size,
          borderRadius:p.shape,background:color,
          boxShadow:`0 0 ${p.size*2.5}px ${color}`,
          "--tx":p.tx,"--ty":p.ty,
          animation:`particleFly .65s ease ${p.delay}s forwards`,
          transform:"translate(-50%,-50%)"}}/>
      ))}
    </div>
  );
};

// ─── Zone-accurate battle backgrounds ─────────────────────────
const ZONE_BATTLE_BG={
  "0_0": "linear-gradient(180deg,#3a8ed4 0%,#87ceeb 25%,#8bc34a 60%,#4a8a2c 100%)",
  "0_-1":"linear-gradient(180deg,#0e2210 0%,#1e4020 40%,#143016 70%,#0a1e0a 100%)",
  "0_-2":"linear-gradient(180deg,#04040c 0%,#120820 40%,#0c0420 70%,#080218 100%)",
};

// ─── Floating HP bar ───────────────────────────────────────────
const FloatingHPBar=({name,hp,maxHp,mp,maxMp,color,level,showMp=false,align="left"})=>{
  const hpPct=Math.max(0,Math.min(100,(hp/Math.max(1,maxHp))*100));
  const mpPct=showMp?Math.max(0,Math.min(100,(mp/Math.max(1,maxMp||1))*100)):0;
  const hpColor=hpPct>60?"#4CAF50":hpPct>30?"#FFB300":"#F44336";
  return(
    <div style={{display:"flex",flexDirection:"column",
      alignItems:align==="right"?"flex-end":"flex-start",gap:3,
      filter:"drop-shadow(0 2px 8px rgba(0,0,0,.9))",pointerEvents:"none"}}>
      <div style={{display:"flex",alignItems:"center",gap:5,
        flexDirection:align==="right"?"row-reverse":"row"}}>
        <span style={{background:T.purple,borderRadius:"50%",width:16,height:16,
          display:"flex",alignItems:"center",justifyContent:"center",
          fontSize:7,fontFamily:T.fontD,color:"#fff"}}>{level}</span>
        <span style={{fontFamily:T.fontD,fontSize:12,color:"#fff",
          textShadow:"1px 1px 0 rgba(0,0,0,.9)"}}>{name}</span>
      </div>
      <div style={{width:130,height:11,background:"rgba(0,0,0,.7)",
        borderRadius:999,overflow:"hidden",border:"1.5px solid rgba(255,255,255,.18)"}}>
        <div style={{height:"100%",width:`${hpPct}%`,background:hpColor,
          borderRadius:999,transition:"width .55s cubic-bezier(.4,0,.2,1)",
          boxShadow:`0 0 8px ${hpColor}88`}}/>
      </div>
      <div style={{fontSize:8,color:"rgba(255,255,255,.55)",fontFamily:T.fontB}}>
        {Math.max(0,hp)}/{maxHp} HP
      </div>
      {showMp&&<>
        <div style={{width:110,height:7,background:"rgba(0,0,0,.7)",
          borderRadius:999,overflow:"hidden",border:"1px solid rgba(255,255,255,.15)"}}>
          <div style={{height:"100%",width:`${mpPct}%`,background:"#42A5F5",
            borderRadius:999,transition:"width .55s cubic-bezier(.4,0,.2,1)"}}/>
        </div>
        <div style={{fontSize:8,color:"rgba(66,165,245,.7)",fontFamily:T.fontB}}>
          {mp}/{maxMp} MP
        </div>
      </>}
    </div>
  );
};

// ─── Action HUD — z:100, pointer-events: auto ──────────────────
const BattleActionHUD=({player,stats,battle,dispatch,onSpellsToggle,showSpells,selSpell,tapSpell,canTame})=>{
  const {phase}=battle;
  const consumables=player.inventory.filter(i=>ITEMS[i.id]?.type==="consumable");

  // Shared HUD container style — ALWAYS z:100, ALWAYS pointer-events:auto
  const hudStyle={
    position:"absolute",bottom:0,left:0,right:0,
    height:"30%",minHeight:180,maxHeight:260,
    background:"linear-gradient(0deg,rgba(8,5,18,.98),rgba(10,7,22,.95) 70%,rgba(12,8,24,.85))",
    borderTop:"2px solid rgba(255,215,0,.2)",
    zIndex:100,         // CRITICAL — top of all layers
    pointerEvents:"auto", // CRITICAL — always receives clicks
    backdropFilter:"blur(12px)",
    boxShadow:"0 -8px 40px rgba(0,0,0,.6)",
  };

  if(phase==="VICTORY"||phase==="DEFEAT") return(
    <div style={{...hudStyle,display:"flex",justifyContent:"center",alignItems:"center"}}>
      <button
        onClick={()=>dispatch({type:"RETURN_WORLD"})}
        style={{
          padding:"14px 32px",fontSize:16,borderRadius:16,
          background:phase==="VICTORY"
            ?`linear-gradient(135deg,${T.green},${T.greenD})`
            :`linear-gradient(135deg,${T.red},${T.redD})`,
          color:"#fff",border:"none",fontFamily:T.fontD,
          width:240,cursor:"pointer",
          animation:"popIn .4s ease",
          boxShadow:phase==="VICTORY"?`0 0 32px ${T.green}55`:`0 0 32px ${T.red}55`,
          pointerEvents:"auto", // belt-and-suspenders
        }}>
        {phase==="VICTORY"?"🌍 Return to World":"🏥 Revive & Return"}
      </button>
    </div>
  );

  if(phase!=="SELECT") return(
    <div style={{...hudStyle,display:"flex",justifyContent:"center",alignItems:"center",
      pointerEvents:"none"}}> {/* idle phases: no click needed */}
      <div style={{fontFamily:T.fontD,fontSize:18,
        color:["CAST_CHARGE","CAST_RELEASE"].includes(phase)?T.purpleL:
          ["PET_ADVANCE","PET_HIT","PET_RETREAT"].includes(phase)?T.greenL:
          phase==="ENEMY_ATTACK"?"#EF9A9A":T.gold,
        animation:"floatIdle .6s ease-in-out infinite",
        textShadow:"0 0 20px currentColor"}}>
        {["CAST_CHARGE","CAST_RELEASE"].includes(phase)&&`${SPELLS[battle.pendingSpellId]?.emoji||"✨"} Casting…`}
        {["PET_ADVANCE","PET_HIT","PET_RETREAT"].includes(phase)&&`🐾 Pet attacking…`}
        {phase==="ENEMY_ATTACK"&&`${battle.enemy?.emoji} Enemy attacks…`}
        {phase==="FINANCE_Q"&&"💰 Answer the challenge…"}
      </div>
    </div>
  );

  return(
    <div style={{...hudStyle,display:"flex",flexDirection:"column",
      padding:"12px 16px 14px",gap:10}}>
      {/* Main action row */}
      <div style={{display:"flex",gap:8,justifyContent:"center"}}>
        {[
          {icon:"⚔️",label:"Attack",color:"#EF5350",onClick:()=>dispatch({type:"BASIC_ATTACK"})},
          {icon:"✨",label:"Spells",color:T.purpleL,onClick:onSpellsToggle,active:showSpells},
          {icon:"🐾",label:canTame?"Tame!":"Pet",color:T.purple,
           onClick:()=>dispatch({type:"PREPARE_TAME"}),disabled:!canTame},
          {icon:"🏃",label:"Flee",color:"#90A4AE",onClick:()=>dispatch({type:"ESCAPE"})},
        ].map(({icon,label,color,onClick,active,disabled})=>(
          <button key={label}
            onClick={onClick}
            disabled={!!disabled}
            style={{
              background:active?`${color}28`:"rgba(12,9,24,.9)",
              border:`2px solid ${active?color:color+"55"}`,
              borderRadius:18,padding:"10px 0",minWidth:72,
              display:"flex",flexDirection:"column",alignItems:"center",gap:4,
              cursor:disabled?"not-allowed":"pointer",
              boxShadow:active?`0 0 20px ${color}55`:"0 4px 16px rgba(0,0,0,.5)",
              transition:"all .14s ease",
              opacity:disabled?0.35:1,
              pointerEvents:"auto",   // CRITICAL per-button
              fontFamily:T.fontD,
            }}>
            <span style={{fontSize:22}}>{icon}</span>
            <span style={{color:disabled?"#444":color,fontSize:10,fontFamily:T.fontD}}>{label}</span>
          </button>
        ))}
        {/* Item quick-bar */}
        {consumables.length>0&&(
          <div style={{display:"flex",gap:5,alignItems:"center",
            marginLeft:8,borderLeft:"1px solid rgba(255,255,255,.1)",paddingLeft:8}}>
            {consumables.slice(0,4).map(item=>(
              <button key={item.uuid}
                onClick={()=>dispatch({type:"USE_ITEM_B",payload:{uuid:item.uuid}})}
                title={item.name}
                style={{background:"rgba(12,9,24,.9)",
                  border:"1.5px solid rgba(255,255,255,.15)",
                  borderRadius:12,padding:"7px",fontSize:18,
                  cursor:"pointer",pointerEvents:"auto", // CRITICAL
                  boxShadow:"0 4px 12px rgba(0,0,0,.5)"}}>
                {item.emoji}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Spell grid */}
      {showSpells&&(
        <div style={{display:"flex",flexWrap:"wrap",gap:7,justifyContent:"center",
          animation:"spellGridOpen .22s cubic-bezier(.4,0,.2,1)",
          maxHeight:150,overflowY:"auto",paddingBottom:4}}>
          {(player.spellsKnown||[]).map(id=>SPELLS[id]).filter(Boolean)
            .sort((a,b)=>(a.tier||1)-(b.tier||1))
            .map(sp=>{
              const canCast=player.mp>=sp.mp;
              const isSel=selSpell===sp.id;
              return(
                <div key={sp.id}
                  className={`spcard${!canCast?" sp-disabled":""}${isSel?" sp-sel":""}`}
                  onClick={()=>canCast&&tapSpell(sp.id)}
                  style={{background:isSel?`${sp.color}28`:"rgba(255,255,255,.04)",
                    border:`1.5px solid ${isSel?sp.color:sp.color+"33"}`,
                    borderRadius:14,padding:"7px 9px",
                    display:"flex",flexDirection:"column",alignItems:"center",gap:2,
                    minWidth:62,maxWidth:74,cursor:canCast?"pointer":"not-allowed",
                    pointerEvents:"auto", // CRITICAL
                    boxShadow:isSel?`0 0 16px ${sp.color}55`:"none"}}>
                  <span style={{fontSize:22}}>{sp.emoji}</span>
                  <span style={{color:canCast?sp.color:"#444",fontSize:8,
                    fontFamily:T.fontD,textAlign:"center",lineHeight:1.2}}>
                    {sp.name}
                  </span>
                  <span style={{color:"#42A5F5",fontSize:7,fontFamily:T.fontB}}>{sp.mp}mp</span>
                  {isSel&&<span style={{color:T.gold,fontSize:7,animation:"slideDown .2s ease"}}>
                    Tap again!
                  </span>}
                </div>
              );
            })}
        </div>
      )}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// BATTLE ARENA — Strict layered z-index, fully clickable HUD
// ═══════════════════════════════════════════════════════════════
export const BattleArena=({state,dispatch})=>{
  const {player,battle,screenShake}=state;
  if(!player||!battle) return null;
  const {enemy,phase,log,spellMultiplier}=battle;
  const st=effStats(player);
  const tier=getZoneTier(player.zx,player.zy);
  const zoneKey=`${player.zx}_${player.zy}`;

  const [showSpells,setShowSpells]=useState(false);
  const [selSpell,setSelSpell]=useState(null);
  const [petPx,setPetPx]=useState(0);
  const [showImpact,setShowImpact]=useState(false);
  const phaseRef=useRef(null); const selTimer=useRef(null);

  // Phase automation timers
  useEffect(()=>{
    if(phase!=="CAST_CHARGE") return;
    phaseRef.current=setTimeout(()=>dispatch({type:"PHASE_CAST_RELEASE"}),PHASE_T.CAST_CHARGE);
    return()=>clearTimeout(phaseRef.current);
  },[phase,dispatch]);
  useEffect(()=>{
    if(phase!=="CAST_RELEASE") return;
    phaseRef.current=setTimeout(()=>dispatch({type:"RESOLVE_SPELL_DAMAGE"}),PHASE_T.CAST_RELEASE);
    return()=>clearTimeout(phaseRef.current);
  },[phase,dispatch]);
  useEffect(()=>{
    if(phase!=="PET_ADVANCE") return;
    let s=null;
    const a=ts=>{if(!s)s=ts;const p=Math.min(1,(ts-s)/PHASE_T.PET_ADVANCE);setPetPx(p*220);
      if(p<1)requestAnimationFrame(a); else dispatch({type:"PHASE_PET_HIT"});};
    requestAnimationFrame(a);
  },[phase,dispatch]);
  useEffect(()=>{
    if(phase!=="PET_HIT") return;
    setShowImpact(true); setTimeout(()=>setShowImpact(false),300);
    phaseRef.current=setTimeout(()=>dispatch({type:"RESOLVE_PET_DAMAGE"}),PHASE_T.PET_HIT);
    return()=>clearTimeout(phaseRef.current);
  },[phase,dispatch]);
  useEffect(()=>{
    if(phase!=="PET_RETREAT") return;
    let s=null;
    const a=ts=>{if(!s)s=ts;const p=Math.min(1,(ts-s)/PHASE_T.PET_RETREAT);
      setPetPx((1-p)*220);if(p<1)requestAnimationFrame(a);
      else{setPetPx(0);dispatch({type:"PHASE_ENEMY_ATTACK"});}};
    requestAnimationFrame(a);
  },[phase,dispatch]);
  useEffect(()=>{
    if(phase!=="ENEMY_ATTACK") return;
    phaseRef.current=setTimeout(()=>dispatch({type:"RESOLVE_ENEMY_ATTACK"}),PHASE_T.ENEMY_ATTACK);
    return()=>clearTimeout(phaseRef.current);
  },[phase,dispatch]);
  useEffect(()=>()=>clearTimeout(phaseRef.current),[]);

  const tapSpell=useCallback(spId=>{
    if(phase!=="SELECT") return;
    if(selSpell===spId){
      clearTimeout(selTimer.current); setSelSpell(null);
      dispatch({type:"PREPARE_CAST",payload:{spellId:spId}}); setShowSpells(false);
    } else {
      setSelSpell(spId); clearTimeout(selTimer.current);
      selTimer.current=setTimeout(()=>setSelSpell(null),2800);
    }
  },[phase,selSpell,dispatch]);
  useEffect(()=>()=>clearTimeout(selTimer.current),[]);

  const eHpPct=Math.max(0,(enemy.currentHp/enemy.maxHp)*100);
  const canTame=BESTIARY[enemy.id]?.tameable&&eHpPct<30&&phase==="SELECT";
  const petId=player.activePetId;
  const petBase=petId?(PETS[petId]||BESTIARY[petId]):null;
  const petInst=petId?player.party?.find(p=>p.id===petId):null;
  const activePet=petInst||petBase;
  const sp=SPELLS[battle.pendingSpellId];
  const bgGrad=ZONE_BATTLE_BG[zoneKey]||ZONE_BATTLE_BG["0_0"];

  // VFX color/emoji lookup
  const VFX={
    fire:{c:"#FF6B35",e:"🔥"},ice:{c:"#80DEEA",e:"❄️"},earth:{c:"#8D6E63",e:"🪨"},
    water:{c:"#29B6F6",e:"🌊"},lightning:{c:"#FFD600",e:"⚡"},sparkle:{c:"#CE93D8",e:"✨"},
    heal:{c:"#69F0AE",e:"💚"},nova:{c:"#CE93D8",e:"🌟"},meteor:{c:"#FF5722",e:"☄️"},
    storm:{c:"#FFF176",e:"🌪️"},thunder:{c:"#FFD600",e:"⚡"},blizzard:{c:"#B3E5FC",e:"❄️"},
    vortex:{c:"#0288D1",e:"🌀"},rock:{c:"#A1887F",e:"🪨"},
    permafrost:{c:"#B3E5FC",e:"🧊"},grand_heal:{c:"#FFEE58",e:"✨"},
  };
  const vfx=sp?VFX[sp.vfx||"sparkle"]||VFX.sparkle:null;

  return(
    // Root: no pointer-events manipulation — let children control their own
    <div style={{position:"absolute",inset:0,overflow:"hidden",
      animation:screenShake?"screenShake .35s ease":"none"}}>

      {/* ══ Z:1 — BACKGROUND ══════════════════════════ */}
      <div style={{position:"absolute",inset:0,zIndex:1,pointerEvents:"none",
        background:bgGrad,animation:"battleBgPulse 4s ease-in-out infinite"}}/>
      {tier===3&&(
        <div style={{position:"absolute",inset:0,zIndex:2,pointerEvents:"none"}}>
          {Array.from({length:40},(_,i)=>(
            <div key={i} style={{position:"absolute",
              left:`${(i*7.3+3)%100}%`,top:`${(i*11.7+2)%100}%`,
              width:1+(i%3),height:1+(i%3),background:"#fff",borderRadius:"50%",
              opacity:.06+(i%5)*.04,
              animation:`floatIdle ${2+(i%4)*.5}s ease-in-out ${i*.13}s infinite`}}/>
          ))}
        </div>
      )}
      {/* Ground gradient */}
      <div style={{position:"absolute",bottom:0,left:0,right:0,height:"32%",
        zIndex:3,pointerEvents:"none",
        background:tier===1?"linear-gradient(0deg,#2d7a1e,#1e5a14,transparent)":
          tier===2?"linear-gradient(0deg,#0a2210,transparent)":
          "linear-gradient(0deg,#080818,transparent)"}}/>
      <div style={{position:"absolute",bottom:"31%",left:0,right:0,height:2,
        zIndex:4,pointerEvents:"none",
        background:"linear-gradient(90deg,transparent,rgba(255,255,255,.12),transparent)"}}/>

      {/* ══ Z:10 — PHASE HEADER ══════════════════════ */}
      <div style={{position:"absolute",top:0,left:0,right:0,
        textAlign:"center",padding:"10px 16px 4px",
        fontFamily:T.fontD,fontSize:13,zIndex:10,pointerEvents:"none",
        color:{SELECT:"#fff",FINANCE_Q:T.gold,CAST_CHARGE:T.purpleL,
          CAST_RELEASE:T.gold,PET_ADVANCE:T.greenL,PET_HIT:T.greenL,
          PET_RETREAT:T.green,ENEMY_ATTACK:"#EF9A9A",
          VICTORY:T.greenL,DEFEAT:T.red}[phase]||"#fff",
        textShadow:"0 0 12px currentColor"}}>
        {phase==="SELECT"&&"⚔️ Choose Your Action"}
        {phase==="FINANCE_Q"&&"💰 Finance Challenge!"}
        {["CAST_CHARGE","CAST_RELEASE"].includes(phase)&&`${sp?.emoji||"✨"} Casting ${sp?.name||"Spell"}…`}
        {["PET_ADVANCE","PET_HIT","PET_RETREAT"].includes(phase)&&`${activePet?.emoji||"🐾"} ${activePet?.name||"Pet"} attacks!`}
        {phase==="ENEMY_ATTACK"&&`${enemy.emoji} ${enemy.name} attacks!`}
        {phase==="VICTORY"&&"🎉 Victory!"}
        {phase==="DEFEAT"&&"💀 Defeated…"}
      </div>

      {/* ══ Z:20 — SPRITES + HP BARS ════════════════ */}
      <div style={{position:"absolute",top:40,left:0,right:0,bottom:"32%",
        display:"flex",alignItems:"flex-end",justifyContent:"space-between",
        padding:"0 8% 20px",zIndex:20,pointerEvents:"none"}}>

        {/* LEFT side */}
        <div style={{display:"flex",flexDirection:"column",alignItems:"flex-start",gap:8}}>
          <FloatingHPBar name={player.name} hp={player.hp} maxHp={st.effMaxHp}
            mp={player.mp} maxMp={st.effMaxMp} level={player.level} showMp/>
          <div style={{position:"relative",display:"flex",alignItems:"flex-end"}}>
            {activePet&&(
              <div style={{position:"relative",
                zIndex:["PET_ADVANCE","PET_HIT","PET_RETREAT"].includes(phase)?25:20,
                transform:`translateX(${petPx}px)`,willChange:"transform"}}>
                <span style={{fontSize:72,display:"block",
                  filter:`drop-shadow(0 8px 16px rgba(0,0,0,.7)) drop-shadow(0 0 20px ${petBase?.color||T.purple}99)`,
                  animation:phase==="VICTORY"?"victoryDance 1.2s ease infinite":
                    phase==="PET_HIT"?"petHit .26s ease":"bobPet 2.4s ease-in-out infinite"}}>
                  {activePet.emoji||petBase?.emoji}
                </span>
                {showImpact&&<SpellImpact color={petBase?.color||T.gold} count={16} cx="50%" cy="50%"/>}
              </div>
            )}
            <div style={{position:"relative",marginLeft:-8}}>
              <span style={{fontSize:96,display:"block",
                filter:"drop-shadow(0 10px 20px rgba(0,0,0,.8)) drop-shadow(0 0 20px rgba(255,215,0,.3))",
                animation:phase==="DEFEAT"?"shake .5s ease":
                  phase==="VICTORY"?"victoryDance 1.2s ease infinite":
                  phase==="CAST_CHARGE"?"castCharge .7s ease forwards":
                  phase==="CAST_RELEASE"?"castRelease .44s ease forwards":
                  "floatIdle 3s ease-in-out infinite"}}>
                {player.avatar}
              </span>
              <div style={{position:"absolute",bottom:-6,left:"50%",transform:"translateX(-50%)",
                width:70,height:16,background:"rgba(0,0,0,.5)",borderRadius:"50%",filter:"blur(8px)"}}/>
            </div>
          </div>
        </div>

        {/* CENTER: multiplier */}
        <div style={{position:"absolute",left:"50%",bottom:36,transform:"translateX(-50%)",
          display:"flex",flexDirection:"column",alignItems:"center"}}>
          {["CAST_CHARGE","CAST_RELEASE","PET_ADVANCE"].includes(phase)&&(
            <div style={{fontFamily:T.fontD,fontSize:28,
              color:spellMultiplier>=1.5?T.greenL:spellMultiplier<1?T.red:T.gold,
              animation:"slideUp .3s ease,glowPulse 1s ease-in-out infinite",
              textShadow:"0 0 20px currentColor"}}>
              ×{(spellMultiplier||1).toFixed(1)}
            </div>
          )}
          {phase==="SELECT"&&(
            <div style={{fontFamily:T.fontD,fontSize:16,
              color:"rgba(255,255,255,.12)",letterSpacing:3}}>VS</div>
          )}
        </div>

        {/* RIGHT side */}
        <div style={{display:"flex",flexDirection:"column",alignItems:"flex-end",gap:8}}>
          <FloatingHPBar name={enemy.name} hp={enemy.currentHp} maxHp={enemy.maxHp}
            color={enemy.color} level={enemy.level} align="right"/>
          <div style={{fontSize:8,color:"rgba(255,255,255,.45)",fontFamily:T.fontB,textAlign:"right"}}>
            Weak: <span style={{color:T.greenL}}>{ELEM_CHAIN[enemy.elem]?.toUpperCase()||"?"}</span>
            {" · "}<span style={{color:enemy.color}}>{enemy.elem?.toUpperCase()}</span>
          </div>
          <div style={{position:"relative"}}>
            {enemy.boss&&<div style={{position:"absolute",top:-22,left:"50%",
              transform:"translateX(-50%)",fontFamily:T.fontD,fontSize:11,color:T.red,
              background:"rgba(244,67,54,.18)",border:"1px solid rgba(244,67,54,.4)",
              borderRadius:8,padding:"2px 8px",whiteSpace:"nowrap",
              animation:"glowPulse 1.5s ease-in-out infinite"}}>⚠ BOSS</div>}
            <span style={{fontSize:enemy.boss?120:96,display:"block",transform:"scaleX(-1)",
              filter:`drop-shadow(0 10px 20px rgba(0,0,0,.8)) drop-shadow(0 0 32px ${enemy.color}99)`,
              animation:phase==="ENEMY_ATTACK"?"enemyAttackLunge .58s ease":
                phase==="VICTORY"?"shake .5s ease":"enemyFloat 2.2s ease-in-out infinite"}}>
              {enemy.emoji}
            </span>
            <div style={{position:"absolute",bottom:-6,left:"50%",
              transform:"translateX(-50%) scaleX(-1)",
              width:70,height:16,background:"rgba(0,0,0,.5)",borderRadius:"50%",filter:"blur(8px)"}}/>
          </div>
        </div>

        {/* Damage floats */}
        {(battle.damageFloats||[]).map(f=>(
          <DmgFloat key={f.id} val={f.val} isHeal={f.isHeal} isCrit={f.isCrit}
            x={f.x} y={f.y}
            onDone={()=>dispatch({type:"REMOVE_DAMAGE_FLOAT",payload:{id:f.id}})}/>
        ))}
      </div>

      {/* ══ Z:50 — VFX LAYER (pointer-events: NONE) ═ */}
      <div style={{position:"absolute",inset:0,zIndex:50,pointerEvents:"none"}}>
        {vfx&&phase==="CAST_RELEASE"&&(
          <div style={{position:"absolute",left:"22%",top:"35%",fontSize:36,
            animation:"petCharge .44s cubic-bezier(.4,0,.2,1) forwards",
            filter:`drop-shadow(0 0 16px ${vfx.c})`}}>
            {vfx.e}
          </div>
        )}
        {vfx&&phase==="CAST_CHARGE"&&(
          <div style={{position:"absolute",left:"16%",top:"20%",
            width:80,height:80,borderRadius:"50%",
            background:`radial-gradient(circle,${vfx.c}44 0%,transparent 70%)`,
            animation:"castCharge .7s ease forwards"}}/>
        )}
        {["PET_HIT","CAST_RELEASE"].includes(phase)&&(
          <div style={{position:"absolute",inset:0,
            background:`radial-gradient(circle at 70% 40%,${enemy.color}33 0%,transparent 60%)`,
            animation:"enemyHit .26s ease forwards"}}/>
        )}
      </div>

      {/* ══ Z:80 — BATTLE LOG (pointer-events: NONE) */}
      <div style={{position:"absolute",left:14,right:14,bottom:"32%",marginBottom:8,
        padding:"6px 12px",background:"rgba(0,0,0,.55)",
        backdropFilter:"blur(10px)",borderRadius:12,
        border:"1px solid rgba(255,255,255,.07)",maxHeight:44,overflowY:"hidden",
        zIndex:80,pointerEvents:"none"}}>
        {log.slice(-3).map((line,i)=>{
          const isGood=line.includes("Correct")||line.includes("HP!")||line.includes("assists")||line.includes("🎉");
          const isBad=line.includes("Fumble")||line.includes("defeated")||line.includes("💀");
          return<div key={i} style={{fontFamily:T.fontB,fontSize:10,lineHeight:1.5,
            color:isGood?T.greenL:isBad?"#EF5350":"rgba(255,255,255,.72)"}}>
            {line}
          </div>;
        })}
      </div>

      {/* ══ Z:100 — ACTION HUD (pointer-events: AUTO) */}
      <BattleActionHUD
        player={player} stats={st} battle={battle} dispatch={dispatch}
        onSpellsToggle={()=>setShowSpells(s=>!s)}
        showSpells={showSpells} selSpell={selSpell}
        tapSpell={tapSpell} canTame={canTame}/>
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// FINANCE MODAL
// ═══════════════════════════════════════════════════════════════
export const FinanceModal=({question,type,onAnswer,onClose})=>{
  const [selected,setSelected]=useState(null);
  const [result,setResult]=useState(null);
  const [hearts,setHearts]=useState([]);
  const [checking,setChecking]=useState(false);

  const handleAnswer=useCallback(answer=>{
    if(result||checking) return;
    setSelected(answer); setChecking(true);
    setTimeout(()=>{
      const isCorrect=String(answer)===String(question.correctAnswer);
      setResult(isCorrect?"correct":"wrong"); setChecking(false);
      if(isCorrect) setHearts(Array.from({length:10},(_,i)=>({id:makeUUID(),x:35+Math.random()*30,delay:i*.07})));
      setTimeout(()=>{onAnswer(answer);setSelected(null);setResult(null);setHearts([]);},1400);
    },380);
  },[question,onAnswer,result,checking]);

  const tierColor=question.tier===1?T.green:question.tier===2?T.blue:T.gold;
  const mult=question.bonusMultiplier||1.5;

  return(
    <>
      <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,.88)",
        backdropFilter:"blur(12px)",zIndex:10000,pointerEvents:"auto"}}/>
      <div className="modal-parchment" style={{
        width:"min(520px,94vw)",padding:"32px 28px",zIndex:10001,
        animation:result==="correct"?"correctPulse .5s ease":
          result==="wrong"?"wrongShake .55s ease":"scrollUnfurl .38s cubic-bezier(.4,0,.2,1)"}}>
        {["top:8px;left:12px","top:8px;right:12px","bottom:8px;left:12px","bottom:8px;right:12px"].map((pos,i)=>(
          <div key={i} style={{position:"absolute",...Object.fromEntries(pos.split(";").map(s=>s.split(":"))),
            fontSize:14,opacity:.4,pointerEvents:"none",color:T.gold}}>✦</div>
        ))}
        <div onClick={onClose} style={{position:"absolute",top:12,right:16,
          fontSize:18,cursor:"pointer",color:"rgba(255,255,255,.35)",padding:"4px 8px",
          zIndex:1,pointerEvents:"auto"}}>✕</div>
        {hearts.map(h=>(
          <div key={h.id} style={{position:"absolute",left:`${h.x}%`,top:"50%",
            fontSize:20,pointerEvents:"none",
            animation:`heartFloat 1.5s ease ${h.delay}s forwards`}}>
            {type==="tame"?"💖":"⭐"}
          </div>
        ))}
        <div style={{textAlign:"center",marginBottom:20}}>
          <div style={{fontFamily:T.fontD,fontSize:22,color:T.gold,marginBottom:8,
            textShadow:`0 0 20px ${T.goldGlow}`}}>
            {type==="tame"?"💖 Tame Challenge!":"🔮 Finance Spell!"}
          </div>
          <div style={{display:"flex",gap:6,justifyContent:"center",flexWrap:"wrap",marginBottom:8}}>
            <Badge label={question.difficulty} color="#aaa" size={10}/>
            <Badge label={`✓ = ×${mult.toFixed(1)} power`} color={T.greenL} bg="rgba(105,240,174,.1)" size={10}/>
          </div>
          {question.category&&(
            <div style={{color:"rgba(255,255,255,.4)",fontSize:10,fontFamily:T.fontB}}>
              📚 {question.category} — {question.scenario}
            </div>
          )}
        </div>
        <div style={{background:"rgba(255,255,255,.05)",borderRadius:18,
          padding:"18px 22px",marginBottom:22,border:"1.5px solid rgba(255,215,0,.2)"}}>
          <div style={{fontFamily:T.fontB,fontSize:16,color:"#fff",
            lineHeight:1.55,textAlign:"center"}}>
            {question.question}
          </div>
        </div>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
          {question.answers.map((ans,idx)=>{
            const isThis=String(selected)===String(ans);
            const isChecking=isThis&&checking;
            const isCorrectAns=isThis&&result==="correct";
            const isWrongAns=isThis&&result==="wrong";
            return(
              <button key={idx} disabled={!!result||checking}
                onClick={()=>handleAnswer(ans)}
                style={{fontFamily:T.fontD,fontSize:20,padding:"16px",
                  borderRadius:18,
                  border:`2.5px solid ${isChecking?"#FFD700":isCorrectAns?T.green:isWrongAns?T.red:"rgba(255,215,0,.35)"}`,
                  background:isChecking?"rgba(255,215,0,.18)":isCorrectAns?`${T.green}22`:isWrongAns?`${T.red}22`:"rgba(255,255,255,.05)",
                  color:isChecking?T.gold:isCorrectAns?T.greenL:isWrongAns?T.red:T.gold,
                  cursor:result?"not-allowed":"pointer",
                  pointerEvents:"auto", // CRITICAL
                  outline:"none",transition:"all .18s ease",
                  boxShadow:isCorrectAns?`0 0 28px ${T.green}66`:isWrongAns?`0 0 28px ${T.red}55`:"none",
                  animation:isWrongAns?"shake .5s ease":isCorrectAns?"correctPulse .5s ease":"none"}}>
                {String(ans)}{isCorrectAns&&" ✓"}{isWrongAns&&" ✗"}{isChecking&&" ✦"}
              </button>
            );
          })}
        </div>
        {result&&<div style={{marginTop:14,textAlign:"center",fontFamily:T.fontD,fontSize:15,
          color:result==="correct"?T.greenL:T.red,animation:"slideDown .3s ease"}}>
          {result==="correct"?(type==="tame"?"🎉 Smart move! Taming!":"🎉 Correct!"):"❌ Wrong!"}
        </div>}
        {result&&question.explanation&&(
          <div style={{marginTop:6,textAlign:"center",fontFamily:T.fontB,
            fontSize:10,color:"rgba(255,255,255,.45)",animation:"slideDown .4s ease"}}>
            💡 {question.explanation}
          </div>
        )}
      </div>
    </>
  );
};
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 6
// DIALOGUE BOX · ALL OVERLAYS · ROOT APP
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// TYPEWRITER DIALOGUE BOX
// ═══════════════════════════════════════════════════════════════
export const DialogueBox = ({ npcId, onClose }) => {
  const npc = NPCS[npcId] || NPCS.witch;
  const [lineIdx, setLineIdx] = useState(0);
  const [displayed, setDisplayed] = useState("");
  const [done, setDone] = useState(false);
  const timerRef = useRef(null);

  const currentLine = npc.lines[lineIdx % npc.lines.length];

  useEffect(() => {
    setDisplayed(""); setDone(false);
    let i = 0;
    const type = () => {
      if (i <= currentLine.length) {
        setDisplayed(currentLine.slice(0, i));
        if (i === currentLine.length) setDone(true);
        i++;
        timerRef.current = setTimeout(type, 26 + Math.random() * 14);
      }
    };
    timerRef.current = setTimeout(type, 60);
    return () => clearTimeout(timerRef.current);
  }, [currentLine]);

  const advance = () => {
    if (!done) {
      clearTimeout(timerRef.current);
      setDisplayed(currentLine);
      setDone(true);
    } else {
      if (lineIdx >= npc.lines.length - 1) onClose();
      else setLineIdx(i => i + 1);
    }
  };

  return (
    <>
      <div style={{
        position: "fixed", inset: 0, zIndex: 9400, pointerEvents: "auto",
        background: "rgba(0,0,0,.18)",
      }} onClick={advance} />

      <div className="dialogue-box" style={{ zIndex: 9500 }} onClick={advance}>
        <div style={{ display: "flex", alignItems: "stretch", minHeight: 110 }}>

          {/* Portrait */}
          <div style={{
            width: 100, flexShrink: 0,
            background: "linear-gradient(145deg,rgba(255,215,0,.1),rgba(255,215,0,.04))",
            borderRight: "1px solid rgba(255,215,0,.18)",
            display: "flex", flexDirection: "column",
            alignItems: "center", justifyContent: "center", gap: 6, padding: "12px 8px",
          }}>
            <div style={{
              fontSize: 48, animation: "floatIdle 3s ease-in-out infinite",
              filter: "drop-shadow(0 0 14px rgba(255,215,0,.4))",
            }}>
              {npc.portrait || npc.emoji}
            </div>
            <div style={{
              fontFamily: T.fontD, fontSize: 9, color: T.gold,
              textAlign: "center", lineHeight: 1.3, maxWidth: 84,
            }}>
              {npc.name}
            </div>
          </div>

          {/* Text area */}
          <div style={{
            flex: 1, padding: "14px 18px",
            display: "flex", flexDirection: "column", justifyContent: "space-between",
          }}>
            <div style={{
              fontFamily: T.fontB, fontSize: 14, color: "rgba(255,255,255,.9)",
              lineHeight: 1.68, minHeight: 56,
            }}>
              <span style={{ color: "rgba(255,215,0,.5)", marginRight: 4 }}>"</span>
              {displayed}
              {!done && <span className="typewriter-cursor" />}
              <span style={{ color: "rgba(255,215,0,.5)", marginLeft: 2 }}>"</span>
            </div>

            <div style={{
              display: "flex", justifyContent: "space-between",
              alignItems: "center", marginTop: 8,
            }}>
              <div style={{ fontSize: 9, color: "rgba(255,255,255,.25)", fontFamily: T.fontB }}>
                {lineIdx + 1}/{npc.lines.length}
              </div>
              <div style={{
                fontFamily: T.fontD, fontSize: 11, color: T.gold,
                animation: done ? "glowPulse 1.2s ease-in-out infinite" : "none",
                opacity: done ? 1 : 0.4,
                display: "flex", alignItems: "center", gap: 4,
              }}>
                {lineIdx >= npc.lines.length - 1 ? "[Close]" : "[Next]"}
                <span style={{ animation: done ? "floatIdle .7s ease-in-out infinite" : "none" }}>►</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

// ═══════════════════════════════════════════════════════════════
// SHARED SHEET — centered modal, gold border, not bottom drawer
// ═══════════════════════════════════════════════════════════════
const Sheet = ({ title, children, onClose, maxW = 560 }) => (
  <>
    <div style={{
      position: "fixed", inset: 0,
      background: "rgba(0,0,0,.78)", backdropFilter: "blur(6px)",
      zIndex: 9500, pointerEvents: "auto",
    }} onClick={onClose} />

    <div className="modal-parchment" style={{
      width: `min(${maxW}px, 94vw)`,
      maxHeight: "88vh",
      display: "flex", flexDirection: "column",
      animation: "popInCenter .28s ease",
      zIndex: 9501,
    }}>
      {/* Header */}
      <div style={{
        display: "flex", alignItems: "center",
        justifyContent: "space-between",
        padding: "18px 22px 12px",
        borderBottom: "1px solid rgba(255,215,0,.15)",
        flexShrink: 0,
      }}>
        <div style={{
          fontFamily: T.fontD, fontSize: 22, color: T.gold,
          textShadow: `0 0 18px ${T.goldGlow}`,
        }}>
          {title}
        </div>
        <button className="gbtn" onClick={onClose} style={{
          padding: "5px 14px", fontSize: 11, borderRadius: 12,
          background: "rgba(255,255,255,.07)",
          border: "1px solid rgba(255,255,255,.12)", color: "rgba(255,255,255,.5)",
        }}>✕</button>
      </div>

      {/* Scrollable content */}
      <div style={{ overflowY: "auto", flex: 1, padding: "16px 20px" }}>
        {children}
      </div>
    </div>
  </>
);

// ═══════════════════════════════════════════════════════════════
// SHOP OVERLAY
// ═══════════════════════════════════════════════════════════════
const ShopOverlay = ({ player, dispatch, onClose }) => {
  const [tab, setTab] = useState("buy");
  const shopItems = Object.values(ITEMS).filter(i => i.price);
  const sellable = player.inventory.filter(i => i.price);

  return (
    <Sheet title="🏪 Item Shop" onClose={onClose}>
      <div style={{ display: "flex", gap: 8, marginBottom: 16, alignItems: "center" }}>
        {["buy", "sell"].map(t => (
          <button key={t} className="gbtn" onClick={() => setTab(t)} style={{
            padding: "7px 16px", fontSize: 12, borderRadius: 12,
            background: tab === t ? `linear-gradient(135deg,${T.gold},${T.goldD})` : "rgba(255,255,255,.07)",
            color: tab === t ? "#000" : "#aaa",
            border: `1.5px solid ${tab === t ? T.gold : "rgba(255,255,255,.1)"}`,
          }}>
            {t === "buy" ? "🛒 Buy" : "💰 Sell"}
          </button>
        ))}
        <div style={{ marginLeft: "auto", fontFamily: T.fontD, fontSize: 15, color: T.gold }}>
          💰 {player.gold}g
        </div>
      </div>

      {tab === "buy" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {shopItems.map(it => (
            <RarityCard key={it.id} rarity={it.rarity} style={{ padding: "10px 14px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <span style={{ fontSize: 26 }}>{it.emoji}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: T.fontD, color: RC[it.rarity]?.color || "#fff", fontSize: 14 }}>
                    {it.name}
                  </div>
                  <div style={{ color: "#555", fontSize: 10, fontFamily: T.fontB, marginBottom: 4 }}>
                    {it.desc}
                  </div>
                  {it.stats && (
                    <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                      {Object.entries(it.stats).map(([k, v]) => (
                        <Badge key={k} label={`+${v} ${k.toUpperCase()}`} color={RC[it.rarity]?.color || "#888"} />
                      ))}
                    </div>
                  )}
                </div>
                <button className="gbtn" disabled={player.gold < it.price || player.inventory.length >= 30}
                  onClick={() => dispatch({ type: "BUY_ITEM", payload: { itemId: it.id } })}
                  style={{
                    padding: "7px 14px", fontSize: 12, borderRadius: 12,
                    background: `linear-gradient(135deg,${T.gold},${T.goldD})`,
                    color: "#000", border: "none", fontFamily: T.fontD, whiteSpace: "nowrap",
                  }}>
                  {it.price}g
                </button>
              </div>
            </RarityCard>
          ))}
        </div>
      )}

      {tab === "sell" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {!sellable.length && (
            <div style={{ color: "#444", fontFamily: T.fontB, textAlign: "center", padding: 32 }}>
              Nothing to sell.
            </div>
          )}
          {sellable.map(it => {
            const sell = Math.floor((it.price || 0) * 0.4);
            return (
              <RarityCard key={it.uuid} rarity={it.rarity} style={{ padding: "10px 14px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                  <span style={{ fontSize: 26 }}>{it.emoji}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontFamily: T.fontD, color: RC[it.rarity]?.color || "#fff", fontSize: 13 }}>
                      {it.name}
                    </div>
                    <div style={{ color: "#555", fontSize: 10 }}>{it.desc}</div>
                  </div>
                  <button className="gbtn"
                    onClick={() => dispatch({ type: "SELL_ITEM", payload: { uuid: it.uuid } })}
                    style={{
                      padding: "7px 12px", fontSize: 12, borderRadius: 12,
                      background: "rgba(255,215,0,.15)", border: `1.5px solid ${T.gold}44`,
                      color: T.gold, fontFamily: T.fontD,
                    }}>
                    +{sell}g
                  </button>
                </div>
              </RarityCard>
            );
          })}
        </div>
      )}
    </Sheet>
  );
};

// ═══════════════════════════════════════════════════════════════
// INVENTORY OVERLAY
// ═══════════════════════════════════════════════════════════════
const InventoryOverlay = ({ player, stats, dispatch, onClose }) => {
  const [tab, setTab] = useState("items");
  const SLOTS = ["weapon", "offhand", "head", "body", "neck", "ring"];

  return (
    <Sheet title="🎒 Inventory" onClose={onClose}>
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {["items", "gear"].map(t => (
          <button key={t} className="gbtn" onClick={() => setTab(t)} style={{
            padding: "7px 16px", fontSize: 12, borderRadius: 12,
            background: tab === t ? `linear-gradient(135deg,${T.purple},${T.purpleD})` : "rgba(255,255,255,.07)",
            color: tab === t ? "#fff" : "#aaa",
            border: `1.5px solid ${tab === t ? T.purple : "rgba(255,255,255,.1)"}`,
          }}>
            {t === "items" ? "🧪 Items" : "🛡 Gear"}
          </button>
        ))}
        <div style={{ marginLeft: "auto", fontSize: 10, color: "#555", alignSelf: "center", fontFamily: T.fontB }}>
          {player.inventory.length}/30
        </div>
      </div>

      {tab === "items" && (
        <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
          {!player.inventory.length && (
            <div style={{ color: "#444", fontFamily: T.fontB, textAlign: "center", padding: 32 }}>
              Inventory empty.
            </div>
          )}
          {player.inventory.map(it => (
            <RarityCard key={it.uuid} rarity={it.rarity} style={{ padding: "9px 13px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontSize: 24 }}>{it.emoji}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: T.fontD, color: RC[it.rarity]?.color || "#fff", fontSize: 13 }}>
                    {it.name}
                  </div>
                  <div style={{ color: "#555", fontSize: 10, fontFamily: T.fontB }}>{it.desc}</div>
                </div>
                {it.type === "consumable" && (
                  <button className="gbtn"
                    onClick={() => dispatch({ type: "USE_ITEM", payload: { uuid: it.uuid } })}
                    style={{
                      padding: "5px 12px", fontSize: 11, borderRadius: 10,
                      background: `rgba(76,175,80,.2)`, border: `1.5px solid ${T.green}55`,
                      color: T.green, fontFamily: T.fontD,
                    }}>
                    Use
                  </button>
                )}
                {it.type === "gear" && (
                  <button className="gbtn"
                    onClick={() => dispatch({ type: "EQUIP_GEAR", payload: { itemId: it.id } })}
                    style={{
                      padding: "5px 12px", fontSize: 11, borderRadius: 10,
                      background: "rgba(33,150,243,.2)", border: "1.5px solid rgba(33,150,243,.4)",
                      color: T.blue, fontFamily: T.fontD,
                    }}>
                    Equip
                  </button>
                )}
              </div>
            </RarityCard>
          ))}
        </div>
      )}

      {tab === "gear" && (
        <div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 16 }}>
            {SLOTS.map(slot => {
              const eqId = player.equippedGear[slot];
              const eq = eqId ? ITEMS[eqId] : null;
              return (
                <div key={slot} style={{
                  background: "rgba(255,255,255,.04)", borderRadius: 12, padding: "9px 11px",
                  border: `1.5px solid ${eq ? (RC[eq.rarity]?.color || "#333") + "55" : "#22222266"}`,
                }}>
                  <div style={{ color: "#444", fontSize: 9, textTransform: "uppercase", fontFamily: T.fontB, marginBottom: 4 }}>
                    {slot}
                  </div>
                  {eq ? (
                    <>
                      <div style={{ fontFamily: T.fontD, color: RC[eq.rarity]?.color || "#aaa", fontSize: 12 }}>
                        {eq.emoji} {eq.name}
                      </div>
                      <div style={{ display: "flex", gap: 3, marginTop: 3, flexWrap: "wrap" }}>
                        {Object.entries(eq.stats || {}).map(([k, v]) => (
                          <Badge key={k} label={`+${v}${k}`} color={RC[eq.rarity]?.color || "#888"} />
                        ))}
                      </div>
                      <button className="gbtn"
                        onClick={() => dispatch({ type: "UNEQUIP_GEAR", payload: { slot } })}
                        style={{
                          marginTop: 6, padding: "3px 10px", fontSize: 9, borderRadius: 8,
                          background: "rgba(255,255,255,.06)", border: "1px solid rgba(255,255,255,.1)",
                          color: "#666", fontFamily: T.fontD,
                        }}>
                        Remove
                      </button>
                    </>
                  ) : (
                    <div style={{ color: "#2a2a2a", fontSize: 11, fontStyle: "italic" }}>— Empty —</div>
                  )}
                </div>
              );
            })}
          </div>

          <div style={{
            background: "rgba(255,215,0,.06)", borderRadius: 14, padding: "12px 16px",
            border: "1px solid rgba(255,215,0,.15)",
          }}>
            <div style={{ fontFamily: T.fontD, color: T.gold, fontSize: 14, marginBottom: 9 }}>
              ⚡ Effective Stats
            </div>
            {[
              ["⚔️ ATK", stats.effAtk, "#EF5350"],
              ["🛡️ DEF", stats.effDef, "#42A5F5"],
              ["❤️ MaxHP", stats.effMaxHp, "#4CAF50"],
              ["💧 MaxMP", stats.effMaxMp, "#CE93D8"],
            ].map(([l, v, c]) => (
              <div key={l} style={{
                display: "flex", justifyContent: "space-between",
                fontSize: 12, fontFamily: T.fontB, marginBottom: 5,
              }}>
                <span style={{ color: "#999" }}>{l}</span>
                <span style={{ color: c, fontFamily: T.fontD, fontSize: 13 }}>{v}</span>
              </div>
            ))}
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, fontFamily: T.fontB }}>
              <span style={{ color: "#999" }}>💥 Crit%</span>
              <span style={{ color: T.gold, fontFamily: T.fontD, fontSize: 13 }}>
                {(stats.critChance * 100).toFixed(1)}%
              </span>
            </div>
          </div>
        </div>
      )}
    </Sheet>
  );
};

// ═══════════════════════════════════════════════════════════════
// SPELL LIBRARY OVERLAY
// ═══════════════════════════════════════════════════════════════
const LibraryOverlay = ({ player, onClose }) => {
  const [filter, setFilter] = useState("all");
  const filtered = Object.values(SPELLS).filter(sp =>
    filter === "all" || String(sp.tier) === filter
  );

  return (
    <Sheet title="📚 Spell Library" onClose={onClose}>
      <div style={{ display: "flex", gap: 7, marginBottom: 16 }}>
        {["all", "1", "2", "3"].map(t => (
          <button key={t} className="gbtn" onClick={() => setFilter(t)} style={{
            padding: "6px 14px", fontSize: 11, borderRadius: 11,
            background: filter === t ? `linear-gradient(135deg,${T.purple},${T.purpleD})` : "rgba(255,255,255,.07)",
            color: filter === t ? "#fff" : "#aaa",
            border: `1.5px solid ${filter === t ? T.purple : "rgba(255,255,255,.1)"}`,
          }}>
            {t === "all" ? "All" : `Tier ${t}`}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
        {filtered.map(sp => {
          const known = (player.spellsKnown || []).includes(sp.id);
          return (
            <div key={sp.id} style={{
              display: "flex", alignItems: "center", gap: 12,
              background: known ? "rgba(255,255,255,.06)" : "rgba(0,0,0,.28)",
              borderRadius: 14, padding: "11px 14px",
              opacity: known ? 1 : 0.44,
              border: `1.5px solid ${known ? sp.color + "44" : "#22222255"}`,
              transition: "all .2s ease",
            }}>
              <span style={{ fontSize: 28, filter: known ? "none" : "grayscale(1)" }}>{sp.emoji}</span>
              <div style={{ flex: 1 }}>
                <div style={{
                  fontFamily: T.fontD, fontSize: 14,
                  color: known ? sp.color : "#444",
                  display: "flex", alignItems: "center", gap: 6, flexWrap: "wrap",
                }}>
                  {sp.name}
                  {known && <Badge label="✓ Known" color={T.gold} bg={`${T.gold}18`} size={8} />}
                  {sp.isHeal && <Badge label="🌿 Heal" color={T.greenL} size={8} />}
                </div>
                <div style={{ color: "#555", fontSize: 10, fontFamily: T.fontB, marginBottom: 5 }}>
                  {sp.desc}
                </div>
                <div style={{ display: "flex", gap: 5, flexWrap: "wrap" }}>
                  <Badge label={`${sp.power} PWR`} color={sp.color} />
                  <Badge label={`${sp.mp} MP`} color="#42A5F5" />
                  <Badge label={sp.elem.toUpperCase()} color={sp.color} bg={`${sp.color}18`} />
                  <Badge label={`Lv.${sp.minLv}+`} color="#555" />
                  <Badge label={`T${sp.tier}`}
                    color={sp.tier === 3 ? T.gold : sp.tier === 2 ? T.purple : "#666"}
                    bg={sp.tier === 3 ? `${T.gold}18` : sp.tier === 2 ? `${T.purple}18` : "transparent"} />
                </div>
              </div>
              {!known && (
                <div style={{ color: "#333", fontSize: 10, fontFamily: T.fontB, whiteSpace: "nowrap" }}>
                  Lv.{sp.minLv}+
                </div>
              )}
            </div>
          );
        })}
      </div>
    </Sheet>
  );
};

// ═══════════════════════════════════════════════════════════════
// PARTY OVERLAY
// ═══════════════════════════════════════════════════════════════
const PartyOverlay = ({ player, dispatch, onClose }) => (
  <Sheet title="🐾 Party & Pets" onClose={onClose}>
    <div style={{
      display: "flex", gap: 8, marginBottom: 16,
      background: "rgba(255,215,0,.06)", borderRadius: 12, padding: "10px 14px",
      border: "1px solid rgba(255,215,0,.14)",
    }}>
      <span style={{ fontFamily: T.fontB, fontSize: 12, color: "#888" }}>
        Total XP: <b style={{ color: T.gold }}>{player.totalXp || 0}</b>
      </span>
      <span style={{ fontFamily: T.fontB, fontSize: 12, color: "#888", marginLeft: 14 }}>
        Party: <b style={{ color: T.green }}>{player.party?.length || 1}</b>/6
      </span>
    </div>

    <div style={{ marginBottom: 12, color: T.gold, fontFamily: T.fontD, fontSize: 13 }}>
      Active Party
    </div>
    <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 22 }}>
      {player.party?.map(petInst => {
        const petBase = PETS[petInst.id];
        if (!petBase) return null;
        const isActive = player.activePetId === petInst.id;
        const evos = PET_EVOLUTIONS[petInst.id] || [];
        const nextEvo = evos.find(e => e.lv > petInst.level);
        return (
          <div key={petInst.uuid} style={{
            display: "flex", alignItems: "center", gap: 12,
            background: isActive ? "rgba(255,215,0,.08)" : "rgba(255,255,255,.04)",
            borderRadius: 18, padding: "12px 14px",
            border: `2px solid ${isActive ? T.gold : (petBase.color || T.purple) + "44"}`,
            boxShadow: isActive ? `0 0 20px ${T.gold}22` : "none",
          }}>
            <div style={{ position: "relative" }}>
              <span style={{ fontSize: 32 }}>{petInst.emoji || petBase.emoji}</span>
              {isActive && (
                <div style={{
                  position: "absolute", bottom: -2, right: -2,
                  background: T.gold, borderRadius: "50%", width: 11, height: 11,
                  border: "1.5px solid #060612",
                }} />
              )}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{
                fontFamily: T.fontD, fontSize: 14, color: petBase.color || T.purple,
                display: "flex", alignItems: "center", gap: 6, marginBottom: 3,
              }}>
                {petInst.name || petBase.name}
                {isActive && <Badge label="ACTIVE" color={T.gold} bg={`${T.gold}22`} size={8} />}
              </div>
              <div style={{ color: "#666", fontSize: 10, fontFamily: T.fontB, marginBottom: 5 }}>
                Lv.{petInst.level} · ⚔{petInst.atk} · 🛡{petInst.def}
                {nextEvo && ` · Evolves Lv.${nextEvo.lv} → ${nextEvo.emoji}`}
              </div>
              <div style={{ marginBottom: 2 }}>
                <StatBar val={petInst.hp} max={petInst.maxHp} color={petBase.color || T.purple} h={5} />
              </div>
              <StatBar val={petInst.xp || 0} max={100 * petInst.level} color="#FFD600" h={3} />
            </div>
            {!isActive && (
              <button className="gbtn" onClick={() => {
                dispatch({ type: "SET_ACTIVE_PET", payload: { petId: petInst.id } });
                dispatch({ type: "SET_TOAST", payload: { msg: `${petBase.emoji} ${petBase.name} is now active!`, t: "info" } });
              }} style={{
                padding: "6px 12px", fontSize: 10, borderRadius: 11,
                background: `${petBase.color || T.purple}22`,
                border: `1.5px solid ${petBase.color || T.purple}55`,
                color: petBase.color || T.purple, fontFamily: T.fontD,
              }}>
                Activate
              </button>
            )}
          </div>
        );
      })}
    </div>

    <div style={{ marginBottom: 10, color: "#555", fontFamily: T.fontD, fontSize: 12 }}>
      Unlockable Companions
    </div>
    <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
      {Object.values(PETS).filter(p => !player.party?.find(pp => pp.id === p.id)).map(pet => {
        const unlocked = (player.totalXp || 0) >= pet.xpReq;
        return (
          <div key={pet.id} style={{
            display: "flex", alignItems: "center", gap: 12,
            background: "rgba(255,255,255,.03)", borderRadius: 14, padding: "10px 14px",
            opacity: unlocked ? 1 : 0.42,
            border: `1px solid ${unlocked ? pet.color + "44" : "#1a1a1a"}`,
          }}>
            <span style={{ fontSize: 28, filter: unlocked ? "none" : "grayscale(1)" }}>{pet.emoji}</span>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: T.fontD, color: unlocked ? pet.color : "#444", fontSize: 13 }}>
                {pet.name}
              </div>
              <div style={{ color: "#555", fontSize: 10, fontFamily: T.fontB }}>{pet.lore}</div>
              <Badge label={pet.xpReq ? `Unlock at ${pet.xpReq}xp` : "Starter"}
                color={unlocked ? pet.color : "#444"} />
            </div>
            {unlocked && (
              <div style={{ color: T.greenL, fontSize: 10, fontFamily: T.fontB }}>
                ✓ Tame in battle!
              </div>
            )}
          </div>
        );
      })}
    </div>
  </Sheet>
);

// ═══════════════════════════════════════════════════════════════
// QUESTS OVERLAY
// ═══════════════════════════════════════════════════════════════
const QuestOverlay = ({ questProgress, player, dispatch, onClose }) => {
  const [filter, setFilter] = useState("all");
  const filtered = QUESTS.filter(q => {
    const qp = questProgress[q.id] || {};
    if (filter === "active")   return !qp.done && !qp.claimed;
    if (filter === "complete") return qp.done && !qp.claimed;
    if (filter === "claimed")  return qp.claimed;
    return true;
  });

  return (
    <Sheet title="📋 Quests" onClose={onClose} maxW={520}>
      <div style={{ display: "flex", gap: 6, marginBottom: 16, flexWrap: "wrap" }}>
        {["all", "active", "complete", "claimed"].map(f => (
          <button key={f} className="gbtn" onClick={() => setFilter(f)} style={{
            padding: "6px 12px", fontSize: 10, borderRadius: 10,
            background: filter === f ? `linear-gradient(135deg,${T.green},${T.greenD})` : "rgba(255,255,255,.07)",
            color: filter === f ? "#fff" : "#aaa",
            border: `1.5px solid ${filter === f ? T.green : "rgba(255,255,255,.1)"}`,
          }}>
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 11 }}>
        {filtered.map(q => {
          const qp = questProgress[q.id] || { progress: 0, done: false, claimed: false };
          const pct = q.goal.n
            ? Math.min(100, ((qp.progress || 0) / q.goal.n) * 100)
            : (qp.done ? 100 : 0);
          return (
            <div key={q.id} style={{
              background: qp.done ? "rgba(105,240,174,.07)" : "rgba(255,255,255,.04)",
              borderRadius: 16, padding: "12px 14px",
              border: `1.5px solid ${qp.done ? T.green + "44" : "#22222255"}`,
              boxShadow: qp.done ? `0 0 12px rgba(105,240,174,.1)` : "none",
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 7 }}>
                <span style={{ fontSize: 20 }}>{q.emoji}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: T.fontD, color: qp.done ? T.green : "#fff", fontSize: 13 }}>
                    {q.name}
                  </div>
                  <div style={{ color: "#555", fontSize: 10, fontFamily: T.fontB }}>{q.desc}</div>
                </div>
                {qp.done && !qp.claimed && (
                  <button className="gbtn"
                    onClick={() => dispatch({ type: "CLAIM_QUEST_REWARD", payload: { questId: q.id } })}
                    style={{
                      padding: "6px 12px", fontSize: 10, borderRadius: 10,
                      background: `linear-gradient(135deg,${T.green},${T.greenD})`,
                      color: "#fff", border: "none", fontFamily: T.fontD,
                      animation: "pulseGreen 1.5s ease-in-out infinite",
                    }}>
                    Claim!
                  </button>
                )}
                {qp.claimed && <Badge label="✓ Done" color={T.green} bg={`${T.green}18`} />}
              </div>
              {q.goal.n && (
                <>
                  <div style={{
                    display: "flex", justifyContent: "space-between",
                    fontSize: 9, color: "#555", marginBottom: 3,
                  }}>
                    <span>{qp.progress || 0}/{q.goal.n}</span>
                    <span>{Math.round(pct)}%</span>
                  </div>
                  <StatBar val={qp.progress || 0} max={q.goal.n} color={T.green} h={6} />
                </>
              )}
              <div style={{ marginTop: 8, display: "flex", gap: 5, flexWrap: "wrap" }}>
                <Badge label={`+${q.reward.xp}xp`} color="#FFD600" />
                <Badge label={`+${q.reward.gold}g`} color={T.gold} />
                {q.reward.spell && (
                  <Badge label={`✨ ${SPELLS[q.reward.spell]?.name || q.reward.spell}`}
                    color={T.purple} bg={`${T.purple}18`} />
                )}
              </div>
            </div>
          );
        })}
      </div>
    </Sheet>
  );
};

// ═══════════════════════════════════════════════════════════════
// OVERLAY STACK
// ═══════════════════════════════════════════════════════════════
export const OverlayStack = ({ state, dispatch }) => {
  const { overlay, overlayData, player, questProgress } = state;
  if (!overlay || !player) return null;
  const stats = effStats(player);
  const close = () => dispatch({ type: "CLOSE_OVERLAY" });

  if (overlay === "shop")      return <ShopOverlay player={player} dispatch={dispatch} onClose={close} />;
  if (overlay === "inventory") return <InventoryOverlay player={player} stats={stats} dispatch={dispatch} onClose={close} />;
  if (overlay === "library")   return <LibraryOverlay player={player} onClose={close} />;
  if (overlay === "party")     return <PartyOverlay player={player} dispatch={dispatch} onClose={close} />;
  if (overlay === "quests")    return <QuestOverlay questProgress={questProgress} player={player} dispatch={dispatch} onClose={close} />;
  return null;
};

// ═══════════════════════════════════════════════════════════════
// CHAR CREATE
// ═══════════════════════════════════════════════════════════════
const AVATARS = [
  "🧙","🧝","🧜","🧛","🧚","🧞","🦸","🦹",
  "🧟","🧌","👸","🤴","🧑‍🚀","🕵️","🫅","🐺",
  "🦊","🐲","🦄","🧑‍🔬",
];

const CharCreate = ({ onStart }) => {
  const [name, setName] = useState("");
  const [avatar, setAvatar] = useState("🧙");
  const [err, setErr] = useState("");
  const [step, setStep] = useState(0);

  const submit = () => {
    if (!name.trim()) { setErr("Enter a hero name!"); return; }
    if (name.trim().length > 20) { setErr("Max 20 characters."); return; }
    onStart(name.trim(), avatar);
  };

  return (
    <div style={{
      position: "absolute", inset: 0,
      display: "flex", flexDirection: "column",
      alignItems: "center", justifyContent: "center",
      background: "linear-gradient(145deg,#040410,#0a0820,#060614)",
      padding: 20, overflow: "auto",
    }}>
      {/* Starfield */}
      {Array.from({ length: 24 }, (_, i) => (
        <div key={i} style={{
          position: "absolute",
          left: `${(i * 7.9 + 2) % 100}%`, top: `${(i * 11.3 + 5) % 100}%`,
          width: 1 + (i % 2), height: 1 + (i % 2),
          background: "#fff", borderRadius: "50%",
          opacity: 0.05 + (i % 4) * 0.04,
          pointerEvents: "none",
          animation: `floatIdle ${2 + (i % 4) * 0.5}s ease-in-out ${i * 0.12}s infinite`,
        }} />
      ))}

      <div style={{
        fontFamily: T.fontD, fontSize: 38, color: T.gold, marginBottom: 4,
        letterSpacing: 4, textShadow: `0 0 32px ${T.goldGlow}`,
        animation: "floatIdle 3s ease-in-out infinite", zIndex: 1,
      }}>
        ⚔️ ShellQuest RPG
      </div>
      <div style={{ color: "#444", fontSize: 12, fontFamily: T.fontB, marginBottom: 32, letterSpacing: 1.5, zIndex: 1 }}>
        Finance-Powered Adventure
      </div>

      <div style={{
        fontSize: 80, marginBottom: 22, zIndex: 1,
        animation: "floatIdle 3s ease-in-out infinite",
        filter: `drop-shadow(0 0 28px ${T.goldGlow})`,
      }}>
        {avatar}
      </div>

      {step === 0 && (
        <div style={{ zIndex: 1, display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ color: "#888", fontSize: 11, fontFamily: T.fontB, marginBottom: 14 }}>
            Choose your hero
          </div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 10, justifyContent: "center", maxWidth: 380, marginBottom: 26 }}>
            {AVATARS.map(a => (
              <div key={a} onClick={() => setAvatar(a)} style={{
                fontSize: 28, cursor: "pointer", padding: 10, borderRadius: 16,
                border: `2.5px solid ${a === avatar ? T.gold : "rgba(255,255,255,.1)"}`,
                background: a === avatar ? "rgba(255,215,0,.14)" : "rgba(255,255,255,.04)",
                transition: "all .14s ease",
                transform: a === avatar ? "scale(1.14)" : "scale(1)",
                boxShadow: a === avatar ? `0 0 20px ${T.goldGlow}` : "none",
              }}>
                {a}
              </div>
            ))}
          </div>
          <button className="gbtn" onClick={() => setStep(1)} style={{
            padding: "14px 32px", fontSize: 17, borderRadius: 16, width: 220,
            background: `linear-gradient(135deg,${T.gold},${T.goldD})`,
            color: "#000", border: "none", fontFamily: T.fontD,
            boxShadow: `0 0 28px ${T.goldGlow}`,
          }}>
            Next →
          </button>
        </div>
      )}

      {step === 1 && (
        <div style={{ zIndex: 1, display: "flex", flexDirection: "column", alignItems: "center" }}>
          <div style={{ color: "#888", fontSize: 11, fontFamily: T.fontB, marginBottom: 14 }}>
            Name your hero
          </div>
          <input value={name}
            onChange={e => { setName(e.target.value); setErr(""); }}
            onKeyDown={e => e.key === "Enter" && submit()}
            placeholder="Your hero's name…" autoFocus
            style={{
              width: 288, padding: "13px 22px", borderRadius: 18, marginBottom: 8,
              background: "rgba(255,255,255,.07)",
              border: `2px solid rgba(255,215,0,.36)`,
              color: "#fff", fontSize: 17, fontFamily: T.fontB,
              outline: "none", textAlign: "center",
            }} />
          {err && <div style={{ color: T.red, fontSize: 12, marginBottom: 8 }}>{err}</div>}

          <div style={{
            background: "rgba(255,215,0,.06)", border: "1.5px solid rgba(255,215,0,.2)",
            borderRadius: 18, padding: "14px 20px", maxWidth: 320,
            marginBottom: 22, textAlign: "center",
          }}>
            <div style={{ fontFamily: T.fontD, color: T.gold, fontSize: 14, marginBottom: 6 }}>
              💰 How Combat Works
            </div>
            <div style={{ color: "#777", fontSize: 11, fontFamily: T.fontB, lineHeight: 1.6 }}>
              Cast spells → answer{" "}
              <span style={{ color: T.gold }}>Finance Challenges</span>.<br />
              Correct = <span style={{ color: T.greenL }}>×1.5–1.8 power bonus!</span>{" "}
              Wrong = <span style={{ color: T.red }}>×0.5 weak attack.</span>
            </div>
          </div>

          <div style={{ display: "flex", gap: 10 }}>
            <button className="gbtn" onClick={() => setStep(0)} style={{
              padding: "11px 22px", fontSize: 14, borderRadius: 14,
              background: "rgba(255,255,255,.08)", color: "#777",
              border: "1.5px solid rgba(255,255,255,.12)", fontFamily: T.fontD,
            }}>
              ← Back
            </button>
            <button className="gbtn" onClick={submit} style={{
              padding: "14px 30px", fontSize: 17, borderRadius: 16,
              background: `linear-gradient(135deg,${T.gold},${T.goldD})`,
              color: "#000", border: "none", fontFamily: T.fontD,
              boxShadow: `0 0 28px ${T.goldGlow}`,
            }}>
              ⚔️ Begin Adventure
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

// ─── Preloader ─────────────────────────────────────────────────
const Preloader = ({ onDone }) => {
  const [progress, setProgress] = useState(0);
  const [dots, setDots] = useState(".");
  useEffect(() => {
    const steps = [
      { pct: 20, delay: 180 }, { pct: 45, delay: 260 },
      { pct: 65, delay: 210 }, { pct: 82, delay: 240 }, { pct: 100, delay: 180 },
    ];
    let i = 0;
    const run = () => {
      if (i >= steps.length) { setTimeout(onDone, 320); return; }
      setProgress(steps[i].pct);
      setTimeout(run, steps[i].delay);
      i++;
    };
    run();
  }, [onDone]);
  useEffect(() => {
    const t = setInterval(() => setDots(d => d.length >= 3 ? "." : d + "."), 420);
    return () => clearInterval(t);
  }, []);
  const orbs = [
    { color: T.gold, delay: 0 },
    { color: T.purpleL, delay: 0.44 },
    { color: T.greenL, delay: 0.88 },
  ];
  return (
    <div style={{
      position: "absolute", inset: 0,
      display: "flex", flexDirection: "column",
      alignItems: "center", justifyContent: "center",
      background: "linear-gradient(135deg,#060612,#0d0a24,#060612)",
      zIndex: 9000,
    }}>
      <div style={{ position: "relative", width: 100, height: 100, marginBottom: 30 }}>
        <div style={{
          position: "absolute", top: "50%", left: "50%",
          transform: "translate(-50%,-50%)",
          fontSize: 38, animation: "floatIdle 2s ease-in-out infinite",
        }}>⚔️</div>
        {orbs.map((o, i) => (
          <div key={i} style={{
            position: "absolute", top: "50%", left: "50%",
            width: 11, height: 11, borderRadius: "50%",
            background: o.color, boxShadow: `0 0 14px ${o.color}`,
            animation: `orbitOrb 1.4s linear ${o.delay}s infinite`,
            transformOrigin: "0 0",
          }} />
        ))}
      </div>
      <div style={{
        fontFamily: T.fontD, fontSize: 32, color: T.gold, marginBottom: 8,
        letterSpacing: 3, textShadow: `0 0 30px ${T.goldGlow}`,
      }}>
        ShellQuest RPG
      </div>
      <div style={{ color: "#555", fontSize: 13, fontFamily: T.fontB, marginBottom: 30 }}>
        {progress < 100 ? `Loading${dots}` : "Ready!"}
      </div>
      <div style={{
        width: 230, height: 10, background: "rgba(255,255,255,.08)",
        borderRadius: 999, overflow: "hidden",
        border: "1px solid rgba(255,215,0,.18)",
      }}>
        <div style={{
          height: "100%", width: `${progress}%`,
          background: `linear-gradient(90deg,${T.goldD},${T.gold})`,
          borderRadius: 999, transition: "width .32s ease",
          boxShadow: `0 0 12px ${T.goldGlow}`,
        }} />
      </div>
      <div style={{ color: T.gold, fontSize: 12, fontFamily: T.fontB, marginTop: 8 }}>
        {progress}%
      </div>
    </div>
  );
};

const LoadingScreen = () => (
  <div style={{
    position: "absolute", inset: 0,
    display: "flex", flexDirection: "column",
    alignItems: "center", justifyContent: "center",
    background: "#060612", zIndex: 9000,
  }}>
    <div style={{ fontSize: 64, animation: "floatIdle 2s ease-in-out infinite" }}>⚔️</div>
    <div style={{ fontFamily: T.fontD, fontSize: 26, color: T.gold, marginTop: 18, letterSpacing: 2 }}>
      ShellQuest RPG
    </div>
    <div style={{ color: "#444", fontSize: 13, fontFamily: T.fontB, marginTop: 12 }}>
      Generating world…
    </div>
  </div>
);


// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 7
// LEVEL-UP SCREEN · VICTORY FANFARE · DEFEAT · EVOLUTION CUTSCENE
// ═══════════════════════════════════════════════════════════════

// ─── Confetti particle system ──────────────────────────────────
const ConfettiParticle = ({ x, color, delay, shape }) => {
  const size = 6 + Math.random() * 8;
  return (
    <div style={{
      position: "absolute",
      left: `${x}%`, top: "-10px",
      width: shape === "circle" ? size : size * 0.6,
      height: shape === "circle" ? size : size * 1.4,
      background: color,
      borderRadius: shape === "circle" ? "50%" : shape === "square" ? "2px" : "50% 0",
      opacity: 0,
      "--tx": `${(Math.random() - 0.5) * 120}px`,
      "--ty": `${80 + Math.random() * 120}vh`,
      animation: `particleFly ${1.2 + Math.random() * 0.8}s ease ${delay}s forwards`,
      transform: `rotate(${Math.random() * 360}deg)`,
      pointerEvents: "none",
      zIndex: 99999,
    }} />
  );
};

const ConfettiBurst = ({ count = 60 }) => {
  const particles = useMemo(() => Array.from({ length: count }, (_, i) => ({
    id: i,
    x: Math.random() * 100,
    color: ["#FFD700", "#FF6B35", "#9C27B0", "#4CAF50", "#2196F3", "#FF4081", "#00BCD4"][i % 7],
    delay: Math.random() * 0.8,
    shape: ["circle", "square", "star"][i % 3],
  })), [count]);
  return (
    <div style={{ position: "fixed", inset: 0, pointerEvents: "none", zIndex: 99999, overflow: "hidden" }}>
      {particles.map(p => <ConfettiParticle key={p.id} {...p} />)}
    </div>
  );
};

// ─── Stat reveal row (animates number counting up) ─────────────
const StatRevealRow = ({ icon, label, before, after, color, delay }) => {
  const [shown, setShown] = useState(false);
  const display = useCountUp(shown ? after : before, 800);
  useEffect(() => {
    const t = setTimeout(() => setShown(true), delay);
    return () => clearTimeout(t);
  }, [delay]);
  const diff = after - before;
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "8px 14px", borderRadius: 12,
      background: shown ? `${color}12` : "rgba(255,255,255,.04)",
      border: `1px solid ${shown ? color + "44" : "rgba(255,255,255,.08)"}`,
      transition: "all .4s ease",
      animation: shown ? "slideInLeft .4s ease" : "none",
    }}>
      <span style={{ fontSize: 20, minWidth: 28 }}>{icon}</span>
      <span style={{ fontFamily: T.fontB, color: "#aaa", fontSize: 12, flex: 1 }}>{label}</span>
      <span style={{ fontFamily: T.fontD, color, fontSize: 16 }}>{display}</span>
      {shown && diff > 0 && (
        <span style={{
          fontFamily: T.fontD, color: T.greenL, fontSize: 11,
          animation: "slideInRight .4s ease",
        }}>
          +{diff}
        </span>
      )}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// LEVEL-UP CELEBRATION SCREEN
// ═══════════════════════════════════════════════════════════════
export const LevelUpScreen = ({ player, prevPlayer, newLevel, onClose }) => {
  const [phase, setPhase] = useState("flash"); // flash → reveal → done
  const [showConfetti, setShowConfetti] = useState(false);

  useEffect(() => {
    const t1 = setTimeout(() => { setPhase("reveal"); setShowConfetti(true); }, 400);
    const t2 = setTimeout(() => setPhase("done"), 2000);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  const spellUnlockMap = {
    3: ["multi_spark", "thunder"], 4: ["blizzard"], 5: ["tide"],
    7: ["nova", "meteor"], 8: ["grand_heal"], 9: ["permafrost"], 10: ["gale"],
  };
  const newSpells = spellUnlockMap[newLevel] || [];

  return (
    <>
      {showConfetti && <ConfettiBurst count={80} />}

      {/* Flash overlay */}
      <div style={{
        position: "fixed", inset: 0, zIndex: 99000,
        background: phase === "flash"
          ? "radial-gradient(circle, rgba(255,215,0,.95) 0%, rgba(255,165,0,.8) 50%, rgba(0,0,0,.6) 100%)"
          : "rgba(0,0,0,.88)",
        backdropFilter: "blur(8px)",
        transition: "background .5s ease",
        display: "flex", alignItems: "center", justifyContent: "center",
        pointerEvents: "auto",
      }}>
        <div style={{
          textAlign: "center", maxWidth: 460,
          animation: phase === "flash" ? "none" : "popIn .5s ease",
        }}>
          {/* Level badge */}
          <div style={{
            position: "relative", display: "inline-block", marginBottom: 20,
          }}>
            <div style={{
              width: 120, height: 120, borderRadius: "50%",
              background: `conic-gradient(${T.gold} 0%, ${T.goldD} 50%, ${T.gold} 100%)`,
              display: "flex", alignItems: "center", justifyContent: "center",
              boxShadow: `0 0 60px ${T.gold}88, 0 0 120px ${T.gold}44`,
              animation: "orbitOrb 0s, pulseGold 1.5s ease-in-out infinite",
              margin: "0 auto",
            }}>
              <div style={{
                width: 100, height: 100, borderRadius: "50%",
                background: "linear-gradient(145deg, #1a1230, #0e0820)",
                display: "flex", flexDirection: "column",
                alignItems: "center", justifyContent: "center",
              }}>
                <div style={{ fontFamily: T.fontD, color: "#888", fontSize: 10, letterSpacing: 2 }}>LEVEL</div>
                <div style={{
                  fontFamily: T.fontD, color: T.gold, fontSize: 42, lineHeight: 1,
                  textShadow: `0 0 20px ${T.gold}`,
                  animation: phase !== "flash" ? "countUp .6s ease" : "none",
                }}>
                  {newLevel}
                </div>
              </div>
            </div>
            {/* Orbiting sparkles */}
            {[0, 1, 2, 3].map(i => (
              <div key={i} style={{
                position: "absolute", top: "50%", left: "50%",
                width: 8, height: 8, borderRadius: "50%",
                background: [T.gold, T.purpleL, T.greenL, "#42A5F5"][i],
                boxShadow: `0 0 10px ${[T.gold, T.purpleL, T.greenL, "#42A5F5"][i]}`,
                animation: `orbitOrb ${1.6 + i * 0.4}s linear ${i * 0.3}s infinite`,
                transformOrigin: "0 0",
              }} />
            ))}
          </div>

          <div style={{
            fontFamily: T.fontD, fontSize: 32, color: T.gold,
            marginBottom: 6, textShadow: `0 0 24px ${T.gold}`,
            animation: "glowPulse 1.5s ease-in-out infinite",
          }}>
            ✨ Level Up! ✨
          </div>
          <div style={{
            fontFamily: T.fontB, color: "rgba(255,255,255,.6)",
            fontSize: 13, marginBottom: 26,
          }}>
            {player.name} is now level {newLevel}!
          </div>

          {/* Stat changes */}
          {phase !== "flash" && (
            <div style={{ display: "flex", flexDirection: "column", gap: 7, marginBottom: 20 }}>
              {[
                { icon: "❤️", label: "Max HP", before: player.maxHp - 16, after: player.maxHp, color: "#EF5350", delay: 200 },
                { icon: "💧", label: "Max MP", before: player.maxMp - 11, after: player.maxMp, color: "#42A5F5", delay: 350 },
                { icon: "⚔️", label: "Attack",  before: player.baseAtk - 3, after: player.baseAtk, color: "#FF6B35", delay: 500 },
                { icon: "🛡️", label: "Defense", before: player.baseDef - 2, after: player.baseDef, color: "#78909C", delay: 650 },
              ].map(row => <StatRevealRow key={row.label} {...row} />)}
            </div>
          )}

          {/* New spell unlocks */}
          {newSpells.length > 0 && phase !== "flash" && (
            <div style={{
              background: "rgba(156,39,176,.14)", border: `1.5px solid ${T.purple}55`,
              borderRadius: 14, padding: "10px 16px", marginBottom: 18,
              animation: "slideDown .5s ease .8s both",
            }}>
              <div style={{ fontFamily: T.fontD, color: T.purpleL, fontSize: 12, marginBottom: 8 }}>
                ✨ New Spells Unlocked!
              </div>
              <div style={{ display: "flex", gap: 8, justifyContent: "center", flexWrap: "wrap" }}>
                {newSpells.map(id => {
                  const sp = SPELLS[id];
                  if (!sp) return null;
                  return (
                    <div key={id} style={{
                      background: `${sp.color}22`, border: `1.5px solid ${sp.color}55`,
                      borderRadius: 12, padding: "6px 12px",
                      display: "flex", alignItems: "center", gap: 6,
                    }}>
                      <span style={{ fontSize: 18 }}>{sp.emoji}</span>
                      <span style={{ fontFamily: T.fontD, color: sp.color, fontSize: 11 }}>{sp.name}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {phase === "done" && (
            <button className="gbtn" onClick={onClose} style={{
              padding: "12px 32px", fontSize: 16, borderRadius: 16,
              background: `linear-gradient(135deg,${T.gold},${T.goldD})`,
              color: "#000", border: "none", fontFamily: T.fontD,
              boxShadow: `0 0 28px ${T.goldGlow}`,
              animation: "popIn .4s ease",
            }}>
              Continue ▶
            </button>
          )}
        </div>
      </div>
    </>
  );
};

// ═══════════════════════════════════════════════════════════════
// VICTORY FANFARE
// ═══════════════════════════════════════════════════════════════
export const VictoryFanfare = ({ enemy, xpGained, goldGained, drops, leveledUp, newLevel, onClose }) => {
  const [phase, setPhase] = useState(0); // 0=flash 1=rewards 2=ready
  const xpDisplay = useCountUp(phase >= 1 ? xpGained : 0, 1000);
  const goldDisplay = useCountUp(phase >= 1 ? goldGained : 0, 900);

  useEffect(() => {
    const t1 = setTimeout(() => setPhase(1), 300);
    const t2 = setTimeout(() => setPhase(2), 1800);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  return (
    <>
      <ConfettiBurst count={50} />

      <div style={{
        position: "fixed", inset: 0, zIndex: 9800,
        background: "rgba(0,0,0,.9)", backdropFilter: "blur(8px)",
        display: "flex", alignItems: "center", justifyContent: "center",
        pointerEvents: "auto",
      }}>
        <div style={{
          textAlign: "center", maxWidth: 420,
          animation: "popIn .4s ease",
        }}>
          {/* Victory header */}
          <div style={{
            fontFamily: T.fontD, fontSize: 38, color: T.greenL,
            marginBottom: 6, textShadow: `0 0 28px ${T.greenL}`,
            animation: "glowPulse 1.5s ease-in-out infinite",
          }}>
            🎉 Victory!
          </div>

          {/* Enemy defeated */}
          <div style={{ fontSize: 52, marginBottom: 8, animation: "victoryDance 1.2s ease infinite" }}>
            {enemy?.emoji || "👾"}
          </div>
          <div style={{ fontFamily: T.fontB, color: "#888", fontSize: 12, marginBottom: 22 }}>
            {enemy?.name} was defeated!
          </div>

          {/* Rewards box */}
          {phase >= 1 && (
            <div style={{
              background: "rgba(255,215,0,.07)", border: "1.5px solid rgba(255,215,0,.25)",
              borderRadius: 18, padding: "16px 22px", marginBottom: 18,
              animation: "slideUp .4s ease",
            }}>
              <div style={{ fontFamily: T.fontD, color: T.gold, fontSize: 14, marginBottom: 12 }}>
                ✨ Rewards
              </div>
              <div style={{ display: "flex", justifyContent: "space-around", marginBottom: 12 }}>
                <div style={{ textAlign: "center" }}>
                  <div style={{ fontFamily: T.fontD, color: "#CE93D8", fontSize: 26 }}>+{xpDisplay}</div>
                  <div style={{ color: "#888", fontSize: 10, fontFamily: T.fontB }}>XP</div>
                </div>
                <div style={{ width: 1, background: "rgba(255,255,255,.1)" }} />
                <div style={{ textAlign: "center" }}>
                  <div style={{ fontFamily: T.fontD, color: T.gold, fontSize: 26 }}>+{goldDisplay}g</div>
                  <div style={{ color: "#888", fontSize: 10, fontFamily: T.fontB }}>Gold</div>
                </div>
              </div>

              {/* Item drops */}
              {drops?.length > 0 && (
                <div style={{ display: "flex", gap: 8, justifyContent: "center", flexWrap: "wrap" }}>
                  {drops.map((item, i) => (
                    <div key={i} style={{
                      background: `${RC[item.rarity]?.color || "#888"}18`,
                      border: `1.5px solid ${RC[item.rarity]?.color || "#888"}44`,
                      borderRadius: 10, padding: "5px 10px",
                      display: "flex", alignItems: "center", gap: 5,
                      animation: `popIn .4s ease ${i * 0.12}s both`,
                    }}>
                      <span style={{ fontSize: 16 }}>{item.emoji}</span>
                      <span style={{ fontFamily: T.fontD, color: RC[item.rarity]?.color || "#aaa", fontSize: 10 }}>
                        {item.name}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Level-up badge if leveled */}
          {leveledUp && phase >= 1 && (
            <div style={{
              background: `${T.gold}14`, border: `2px solid ${T.gold}55`,
              borderRadius: 14, padding: "10px 18px", marginBottom: 16,
              fontFamily: T.fontD, color: T.gold, fontSize: 16,
              animation: "pulseGold 1.5s ease-in-out infinite, popIn .5s ease .3s both",
            }}>
              🆙 LEVEL UP → {newLevel}!
            </div>
          )}

          {phase >= 2 && (
            <button className="gbtn" onClick={onClose} style={{
              padding: "12px 32px", fontSize: 16, borderRadius: 16,
              background: `linear-gradient(135deg,${T.green},${T.greenD})`,
              color: "#fff", border: "none", fontFamily: T.fontD,
              boxShadow: `0 0 24px rgba(76,175,80,.5)`,
              animation: "popIn .4s ease",
            }}>
              🌍 Return to World
            </button>
          )}
        </div>
      </div>
    </>
  );
};

// ═══════════════════════════════════════════════════════════════
// DEFEAT SCREEN
// ═══════════════════════════════════════════════════════════════
export const DefeatScreen = ({ enemy, goldLost, onClose }) => {
  const [ready, setReady] = useState(false);
  useEffect(() => { const t = setTimeout(() => setReady(true), 1400); return () => clearTimeout(t); }, []);

  return (
    <div style={{
      position: "fixed", inset: 0, zIndex: 9800,
      background: "radial-gradient(circle, rgba(50,0,0,.98) 0%, rgba(0,0,0,.99) 100%)",
      backdropFilter: "blur(8px)",
      display: "flex", alignItems: "center", justifyContent: "center",
      pointerEvents: "auto",
    }}>
      {/* Dark particles */}
      {Array.from({ length: 20 }, (_, i) => (
        <div key={i} style={{
          position: "absolute",
          left: `${Math.random() * 100}%`, top: `${Math.random() * 100}%`,
          width: 2 + Math.random() * 4, height: 2 + Math.random() * 4,
          background: "#F44336", borderRadius: "50%",
          opacity: 0.15 + Math.random() * 0.2,
          animation: `floatIdle ${2 + Math.random() * 3}s ease-in-out ${Math.random() * 2}s infinite`,
          pointerEvents: "none",
        }} />
      ))}

      <div style={{ textAlign: "center", maxWidth: 380, animation: "popIn .6s ease" }}>
        <div style={{
          fontSize: 72, marginBottom: 16,
          animation: "shake .6s ease",
          filter: "drop-shadow(0 0 20px rgba(244,67,54,.7))",
        }}>
          💀
        </div>

        <div style={{
          fontFamily: T.fontD, fontSize: 36, color: T.red,
          marginBottom: 8, textShadow: "0 0 24px rgba(244,67,54,.8)",
          animation: "glowPulse 2s ease-in-out infinite",
        }}>
          Defeated…
        </div>

        <div style={{ fontFamily: T.fontB, color: "#888", fontSize: 12, marginBottom: 28 }}>
          {enemy?.name} was too powerful this time.
        </div>

        <div style={{
          background: "rgba(244,67,54,.1)", border: "1px solid rgba(244,67,54,.3)",
          borderRadius: 14, padding: "12px 20px", marginBottom: 24,
        }}>
          <div style={{ fontFamily: T.fontB, color: "#EF9A9A", fontSize: 11, marginBottom: 4 }}>
            Penalty
          </div>
          <div style={{ fontFamily: T.fontD, color: T.red, fontSize: 20 }}>
            -{goldLost || 10}g
          </div>
          <div style={{ color: "#666", fontSize: 10, fontFamily: T.fontB, marginTop: 3 }}>
            Revived at 30% HP
          </div>
        </div>

        {ready && (
          <button className="gbtn" onClick={onClose} style={{
            padding: "12px 32px", fontSize: 16, borderRadius: 16,
            background: `linear-gradient(135deg,${T.red},${T.redD})`,
            color: "#fff", border: "none", fontFamily: T.fontD,
            boxShadow: "0 0 24px rgba(244,67,54,.4)",
            animation: "popIn .4s ease",
          }}>
            🏥 Revive & Return
          </button>
        )}
      </div>
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// EVOLUTION CUTSCENE
// ═══════════════════════════════════════════════════════════════
export const EvolutionCutscene = ({ pet, evolutionData, onClose }) => {
  const [phase, setPhase] = useState("charge"); // charge → flash → reveal → done
  const [showBefore, setShowBefore] = useState(true);

  useEffect(() => {
    const seq = [
      { phase: "charge",  delay: 0 },
      { phase: "flash",   delay: 1200 },
      { phase: "reveal",  delay: 1600, hideBefore: true },
      { phase: "done",    delay: 3200 },
    ];
    const timers = seq.map(({ phase, delay, hideBefore }) =>
      setTimeout(() => {
        setPhase(phase);
        if (hideBefore) setShowBefore(false);
      }, delay)
    );
    return () => timers.forEach(clearTimeout);
  }, []);

  const bgColor = {
    charge: "radial-gradient(circle, rgba(20,10,40,.98) 0%, #000 100%)",
    flash:  "radial-gradient(circle, rgba(255,255,255,.99) 0%, rgba(200,180,255,.9) 100%)",
    reveal: "radial-gradient(circle, rgba(20,10,40,.98) 0%, #000 100%)",
    done:   "radial-gradient(circle, rgba(20,10,40,.98) 0%, #000 100%)",
  };

  return (
    <>
      <ConfettiBurst count={60} />

      <div style={{
        position: "fixed", inset: 0, zIndex: 99500,
        background: bgColor[phase],
        transition: "background .3s ease",
        display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center",
        pointerEvents: "auto",
      }}>
        {/* Energy rings during charge */}
        {phase === "charge" && Array.from({ length: 5 }, (_, i) => (
          <div key={i} style={{
            position: "absolute",
            width: 80 + i * 60, height: 80 + i * 60,
            borderRadius: "50%",
            border: `2px solid ${pet.color || T.purple}${Math.round((0.6 - i * 0.1) * 255).toString(16).padStart(2, "0")}`,
            animation: `pulseGold ${0.8 + i * 0.2}s ease-in-out ${i * 0.15}s infinite`,
            pointerEvents: "none",
          }} />
        ))}

        {/* Pet sprite */}
        <div style={{ position: "relative", marginBottom: 24 }}>
          <div style={{
            fontSize: 96,
            filter: phase === "charge"
              ? `drop-shadow(0 0 40px ${pet.color || T.purple}) brightness(${1 + (phase === "charge" ? 1.5 : 1)})`
              : phase === "flash" ? "brightness(10) saturate(0)" : "none",
            animation: phase === "charge" ? "castCharge .7s ease-in-out infinite"
              : phase === "reveal" ? "victoryDance 1s ease infinite"
              : "floatIdle 2s ease-in-out infinite",
            transition: "filter .3s ease",
          }}>
            {showBefore ? pet.emoji : evolutionData.emoji}
          </div>

          {/* Spark particles during charge */}
          {phase === "charge" && (
            <SpellImpact color={pet.color || T.purple} count={24} cx="50%" cy="50%" />
          )}
        </div>

        {/* Text */}
        {phase === "charge" && (
          <div style={{
            fontFamily: T.fontD, fontSize: 22, color: pet.color || T.purple,
            animation: "glowPulse 0.8s ease-in-out infinite",
            textShadow: `0 0 24px ${pet.color || T.purple}`,
          }}>
            {pet.name} is evolving…
          </div>
        )}

        {(phase === "reveal" || phase === "done") && (
          <div style={{ textAlign: "center", animation: "popIn .5s ease" }}>
            <div style={{
              fontFamily: T.fontD, fontSize: 30, color: T.gold,
              marginBottom: 8, textShadow: `0 0 24px ${T.gold}`,
              animation: "glowPulse 1.5s ease-in-out infinite",
            }}>
              ✨ Evolution!
            </div>
            <div style={{ fontFamily: T.fontD, fontSize: 20, color: evolutionData.emoji ? pet.color : T.purpleL, marginBottom: 16 }}>
              → {evolutionData.name}
            </div>
            <div style={{ display: "flex", gap: 16, justifyContent: "center", marginBottom: 20 }}>
              {[
                { label: "ATK", color: "#EF5350" },
                { label: "DEF", color: "#42A5F5" },
                { label: "HP",  color: "#4CAF50" },
              ].map(({ label, color }) => (
                <div key={label} style={{ textAlign: "center" }}>
                  <div style={{ fontFamily: T.fontD, color, fontSize: 18 }}>
                    ×{evolutionData.boost.toFixed(1)}
                  </div>
                  <div style={{ color: "#555", fontSize: 10, fontFamily: T.fontB }}>{label}</div>
                </div>
              ))}
            </div>

            {phase === "done" && (
              <button className="gbtn" onClick={onClose} style={{
                padding: "12px 32px", fontSize: 16, borderRadius: 16,
                background: `linear-gradient(135deg,${T.gold},${T.goldD})`,
                color: "#000", border: "none", fontFamily: T.fontD,
                boxShadow: `0 0 28px ${T.goldGlow}`,
                animation: "popIn .4s ease",
              }}>
                Amazing! ▶
              </button>
            )}
          </div>
        )}
      </div>
    </>
  );
};

// Needed by EvolutionCutscene (re-export for use in BattleArena)
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 8
// WEATHER SYSTEM · DAY/NIGHT CYCLE · AMBIENT FX · MINI-MAP
// ═══════════════════════════════════════════════════════════════

// ─── Weather definitions ───────────────────────────────────────
const WEATHER_TYPES = {
  clear:       { label: "Clear",      icon: "☀️",  overlay: null,           particleEmoji: null,   tint: null },
  cloudy:      { label: "Cloudy",     icon: "⛅",  overlay: "rgba(80,80,100,.15)", particleEmoji: "☁️", tint: null },
  rain:        { label: "Rain",       icon: "🌧️",  overlay: "rgba(40,60,100,.25)", particleEmoji: null,   tint: "rgba(40,60,140,.12)", rainDrops: true },
  storm:       { label: "Storm",      icon: "⛈️",  overlay: "rgba(20,20,60,.40)",  particleEmoji: null,   tint: "rgba(20,20,80,.18)", rainDrops: true, lightning: true },
  fog:         { label: "Foggy",      icon: "🌫️",  overlay: "rgba(180,180,200,.35)", particleEmoji: "💨", tint: "rgba(200,200,220,.08)" },
  snow:        { label: "Snow",       icon: "❄️",  overlay: "rgba(200,220,255,.12)", particleEmoji: null,   snowFlakes: true },
  ash:         { label: "Ash Fall",   icon: "🌋",  overlay: "rgba(60,40,20,.30)",  particleEmoji: null,   ashFlakes: true },
};

// Zone-to-weather probability table
const ZONE_WEATHER = {
  1: ["clear", "clear", "clear", "cloudy", "rain"],
  2: ["cloudy", "rain", "storm", "fog", "clear"],
  3: ["storm", "fog", "ash", "storm", "fog"],
};

// ─── RainDrop canvas layer ─────────────────────────────────────
const RainCanvas = ({ intensity = 1, lightning = false }) => {
  const canvasRef = useRef(null);
  const animRef = useRef(null);
  const flashRef = useRef(null);
  const [flash, setFlash] = useState(false);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;

    const drops = Array.from({ length: Math.floor(120 * intensity) }, () => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      len: 8 + Math.random() * 14,
      speed: 8 + Math.random() * 10,
      opacity: 0.2 + Math.random() * 0.35,
    }));

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.strokeStyle = "rgba(180,200,255,0.6)";
      ctx.lineWidth = 1;
      drops.forEach(d => {
        ctx.globalAlpha = d.opacity;
        ctx.beginPath();
        ctx.moveTo(d.x, d.y);
        ctx.lineTo(d.x + d.len * 0.25, d.y + d.len);
        ctx.stroke();
        d.y += d.speed;
        d.x += d.speed * 0.25;
        if (d.y > canvas.height) {
          d.y = -d.len;
          d.x = Math.random() * canvas.width;
        }
      });
      ctx.globalAlpha = 1;
      animRef.current = requestAnimationFrame(draw);
    };
    draw();

    // Lightning flashes
    if (lightning) {
      const doFlash = () => {
        setFlash(true);
        setTimeout(() => setFlash(false), 120);
        flashRef.current = setTimeout(doFlash, 4000 + Math.random() * 6000);
      };
      flashRef.current = setTimeout(doFlash, 2000 + Math.random() * 3000);
    }

    return () => {
      cancelAnimationFrame(animRef.current);
      clearTimeout(flashRef.current);
    };
  }, [intensity, lightning]);

  return (
    <>
      <canvas ref={canvasRef} style={{
        position: "absolute", inset: 0, pointerEvents: "none", zIndex: 55,
      }} />
      {flash && (
        <div style={{
          position: "absolute", inset: 0, background: "rgba(255,255,255,.18)",
          pointerEvents: "none", zIndex: 56, transition: "opacity .1s",
        }} />
      )}
    </>
  );
};

// ─── Snow / Ash flake layer ────────────────────────────────────
const FlakeLayer = ({ type = "snow", count = 50 }) => {
  const flakes = useMemo(() => Array.from({ length: count }, (_, i) => ({
    id: i,
    emoji: type === "snow" ? "❄" : "·",
    left: Math.random() * 100,
    top: Math.random() * 100,
    size: type === "snow" ? 8 + Math.random() * 10 : 4 + Math.random() * 6,
    dur: 8 + Math.random() * 14,
    delay: Math.random() * -14,
    opacity: type === "snow" ? 0.4 + Math.random() * 0.5 : 0.3 + Math.random() * 0.4,
    color: type === "ash" ? "#8B6040" : "#E3F2FD",
  })), [type, count]);

  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 55, overflow: "hidden" }}>
      {flakes.map(f => (
        <div key={f.id} style={{
          position: "absolute",
          left: `${f.left}%`, top: `-5%`,
          fontSize: f.size, color: f.color,
          opacity: f.opacity,
          animation: `cloudDrift ${f.dur}s linear ${f.delay}s infinite`,
          transform: "rotate(15deg)",
        }}>
          {f.emoji}
        </div>
      ))}
    </div>
  );
};

// ─── Fog layer ─────────────────────────────────────────────────
const FogLayer = () => (
  <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 54, overflow: "hidden" }}>
    {[0, 1, 2, 3].map(i => (
      <div key={i} style={{
        position: "absolute",
        top: `${20 + i * 20}%`, left: "-20%",
        width: "160%", height: "18%",
        background: `rgba(200,210,230,${0.06 + i * 0.03})`,
        borderRadius: "50%",
        filter: "blur(30px)",
        animation: `cloudDrift ${28 + i * 8}s linear ${i * -7}s infinite`,
      }} />
    ))}
  </div>
);

// ═══════════════════════════════════════════════════════════════
// WEATHER SYSTEM HOOK
// ═══════════════════════════════════════════════════════════════
export function useWeather(zx, zy, tick) {
  const [weather, setWeather] = useState("clear");
  const timerRef = useRef(null);

  useEffect(() => {
    const tier = getZoneTier(zx, zy);
    const pool = ZONE_WEATHER[tier] || ZONE_WEATHER[1];
    const pickWeather = () => {
      const w = pool[Math.floor(Math.random() * pool.length)];
      setWeather(w);
      timerRef.current = setTimeout(pickWeather, 45000 + Math.random() * 60000);
    };
    pickWeather();
    return () => clearTimeout(timerRef.current);
  }, [zx, zy]);

  return weather;
}

// ═══════════════════════════════════════════════════════════════
// WEATHER OVERLAY COMPONENT
// ═══════════════════════════════════════════════════════════════
export const WeatherLayer = ({ zx, zy, tick }) => {
  const weather = useWeather(zx, zy, tick);
  const wDef = WEATHER_TYPES[weather] || WEATHER_TYPES.clear;

  return (
    <>
      {/* Tint overlay */}
      {wDef.tint && (
        <div style={{
          position: "absolute", inset: 0, background: wDef.tint,
          pointerEvents: "none", zIndex: 52, transition: "background 3s ease",
        }} />
      )}
      {/* Main overlay */}
      {wDef.overlay && (
        <div style={{
          position: "absolute", inset: 0, background: wDef.overlay,
          pointerEvents: "none", zIndex: 53, transition: "background 3s ease",
        }} />
      )}
      {/* Rain */}
      {wDef.rainDrops && <RainCanvas intensity={weather === "storm" ? 2 : 1} lightning={wDef.lightning} />}
      {/* Snow */}
      {wDef.snowFlakes && <FlakeLayer type="snow" count={60} />}
      {/* Ash */}
      {wDef.ashFlakes && <FlakeLayer type="ash" count={40} />}
      {/* Fog */}
      {weather === "fog" && <FogLayer />}

      {/* Weather indicator — top center */}
      <div style={{
        position: "absolute", top: 14, left: "50%", transform: "translateX(-50%)",
        background: "rgba(0,0,0,.6)", backdropFilter: "blur(8px)",
        borderRadius: 20, padding: "4px 12px",
        display: "flex", alignItems: "center", gap: 5,
        pointerEvents: "none", zIndex: 8050,
        border: "1px solid rgba(255,255,255,.08)",
        opacity: weather === "clear" ? 0 : 0.85,
        transition: "opacity 2s ease",
      }}>
        <span style={{ fontSize: 13 }}>{wDef.icon}</span>
        <span style={{ fontFamily: T.fontB, fontSize: 9, color: "rgba(255,255,255,.6)" }}>
          {wDef.label}
        </span>
      </div>
    </>
  );
};

// ═══════════════════════════════════════════════════════════════
// DAY / NIGHT CYCLE (based on real local time)
// ═══════════════════════════════════════════════════════════════
export function useDayNight() {
  const [timeOfDay, setTimeOfDay] = useState(() => {
    const h = new Date().getHours();
    if (h >= 6  && h < 9)  return "dawn";
    if (h >= 9  && h < 17) return "day";
    if (h >= 17 && h < 20) return "dusk";
    return "night";
  });

  useEffect(() => {
    const update = () => {
      const h = new Date().getHours();
      if (h >= 6  && h < 9)  setTimeOfDay("dawn");
      else if (h >= 9  && h < 17) setTimeOfDay("day");
      else if (h >= 17 && h < 20) setTimeOfDay("dusk");
      else setTimeOfDay("night");
    };
    const t = setInterval(update, 60000);
    return () => clearInterval(t);
  }, []);

  return timeOfDay;
}

const DAY_TINTS = {
  dawn:  { tint: "rgba(255,140,60,.12)",   icon: "🌅", label: "Dawn" },
  day:   { tint: null,                     icon: "☀️",  label: "Day" },
  dusk:  { tint: "rgba(180,60,20,.14)",    icon: "🌇", label: "Dusk" },
  night: { tint: "rgba(10,10,60,.42)",     icon: "🌙", label: "Night" },
};

export const DayNightLayer = ({ zx, zy }) => {
  const tier = getZoneTier(zx, zy);
  if (tier > 1) return null; // Dungeon/woods have their own darkness
  const timeOfDay = useDayNight();
  const def = DAY_TINTS[timeOfDay];
  if (!def.tint) return null;
  return (
    <div style={{
      position: "absolute", inset: 0, background: def.tint,
      pointerEvents: "none", zIndex: 51, transition: "background 8s ease",
    }} />
  );
};

// ═══════════════════════════════════════════════════════════════
// MINI-MAP
// ═══════════════════════════════════════════════════════════════
const MINI_SIZE = 120; // px — total minimap size


export const MiniMap = ({ player, entities, tileMap, statics }) => {
  const [expanded, setExpanded] = useState(false);
  const size = expanded ? 200 : MINI_SIZE;
  const tSz  = Math.floor(size / Math.max(MAP_COLS, MAP_ROWS));

  return (
    <div className="hud-interactive" style={{
      position: "absolute", bottom: 70, right: 14,
      zIndex: 8010,
    }}>
      {/* Toggle button */}
      <button className="gbtn" onClick={() => setExpanded(e => !e)} style={{
        position: "absolute", top: -24, right: 0,
        padding: "2px 8px", fontSize: 8, borderRadius: 6,
        background: "rgba(6,4,18,.8)", border: "1px solid rgba(255,255,255,.1)",
        color: "#888", fontFamily: T.fontB,
      }}>
        {expanded ? "▼ Map" : "▲ Map"}
      </button>

      <div style={{
        width: size + 4, height: size + 4,
        background: "rgba(6,4,18,.92)",
        border: "1.5px solid rgba(255,215,0,.2)",
        borderRadius: 10,
        overflow: "hidden",
        boxShadow: "0 4px 20px rgba(0,0,0,.7)",
        transition: "width .2s ease, height .2s ease",
        position: "relative",
      }}>
        {/* Tile grid */}
        {tileMap?.map((row, ty) => row.map((tileId, tx) => {
          const gfx = TILE_GFX[tileId] || TILE_GFX[0];
          const walkable = WALKABLE.has(tileId);
          return (
            <div key={`${tx}_${ty}`} style={{
              position: "absolute",
              left: tx * tSz + 2, top: ty * tSz + 2,
              width: tSz, height: tSz,
              background: walkable ? gfx.bg : "rgba(0,0,0,.8)",
              opacity: walkable ? 0.85 : 0.5,
            }} />
          );
        }))}

        {/* Entities */}
        {entities?.filter(e => !e.isDefeated && !e.isLooted).map(e => (
          <div key={e.uuid} style={{
            position: "absolute",
            left: e.tx * tSz + tSz / 2 - 2 + 2,
            top:  e.ty * tSz + tSz / 2 - 2 + 2,
            width: 4, height: 4,
            borderRadius: "50%",
            background: e.type === "MONSTER" ? "#EF5350" : T.gold,
            boxShadow: e.type === "MONSTER" ? "0 0 3px #EF5350" : `0 0 3px ${T.gold}`,
          }} />
        ))}

        {/* Statics */}
        {statics?.filter(s => s.type !== "deco").map(s => (
          <div key={s.id} style={{
            position: "absolute",
            left: s.tx * tSz + tSz / 2 - 2 + 2,
            top:  s.ty * tSz + tSz / 2 - 2 + 2,
            width: 4, height: 4,
            borderRadius: "1px",
            background: s.type === "monster" ? "#EF5350" : "#42A5F5",
          }} />
        ))}

        {/* Player dot — pulsing */}
        <div style={{
          position: "absolute",
          left: player.tx * tSz + tSz / 2 - 4 + 2,
          top:  player.ty * tSz + tSz / 2 - 4 + 2,
          width: 8, height: 8,
          borderRadius: "50%",
          background: T.gold,
          boxShadow: `0 0 6px ${T.gold}`,
          animation: "pulseGold 1.2s ease-in-out infinite",
          zIndex: 10,
        }} />

        {/* Zone name overlay */}
        <div style={{
          position: "absolute", bottom: 0, left: 0, right: 0,
          background: "rgba(0,0,0,.7)", padding: "2px 4px",
          fontFamily: T.fontB, fontSize: 7,
          color: "rgba(255,215,0,.7)", textAlign: "center",
        }}>
          {getZoneMeta(player.zx, player.zy)?.name?.split(" ")[0] || "World"}
          {` [${player.zx},${player.zy}]`}
        </div>
      </div>
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// WORLD AMBIENT EFFECTS (fireflies, sparkles, dust motes)
// ═══════════════════════════════════════════════════════════════
export const WorldAmbient = ({ zx, zy }) => {
  const tier = getZoneTier(zx, zy);
  const zm = getZoneMeta(zx, zy);

  const fireflies = useMemo(() => {
    if (tier !== 1) return [];
    return Array.from({ length: 12 }, (_, i) => ({
      id: i,
      x: 5 + Math.random() * 90,
      y: 30 + Math.random() * 60,
      dur: 3 + Math.random() * 4,
      delay: Math.random() * -5,
    }));
  }, [tier]);



  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 8, overflow: "hidden" }}>
      {/* Fireflies (town) */}
      {fireflies.map(f => (
        <div key={f.id} style={{
          position: "absolute", left: `${f.x}%`, top: `${f.y}%`,
          width: 4, height: 4, borderRadius: "50%",
          background: "#FFEE58",
          boxShadow: "0 0 6px #FFEE58, 0 0 12px #FFD600",
          animation: `floatIdle ${f.dur}s ease-in-out ${f.delay}s infinite`,
          opacity: 0.7,
        }} />
      ))}

      {/* Spooky glow orbs (woods) */}
      {tier === 2 && Array.from({ length: 5 }, (_, i) => (
        <div key={i} style={{
          position: "absolute",
          left: `${15 + i * 17}%`, top: `${40 + Math.sin(i * 1.3) * 20}%`,
          width: 16, height: 16, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(156,39,176,.6) 0%, transparent 70%)",
          animation: `floatIdle ${3 + i}s ease-in-out ${i * 0.7}s infinite`,
          pointerEvents: "none",
        }} />
      ))}

      {/* Dungeon ember particles */}
      {tier === 3 && Array.from({ length: 20 }, (_, i) => (
        <div key={i} style={{
          position: "absolute",
          left: `${Math.random() * 100}%`, bottom: `${Math.random() * 40}%`,
          width: 2 + Math.random() * 3, height: 2 + Math.random() * 3,
          borderRadius: "50%",
          background: ["#FF5722", "#FF9800", "#F44336", "#FFEB3B"][i % 4],
          opacity: 0.4 + Math.random() * 0.4,
          animation: `dmgFloat ${1.5 + Math.random() * 2}s ease-out ${Math.random() * -3}s infinite`,
          pointerEvents: "none",
        }} />
      ))}
    </div>
  );
};

// ─── Loot Pop Animation (item drop floats up from position) ────
export const LootPop = ({ item, x, y, onDone }) => {
  useEffect(() => { const t = setTimeout(onDone, 1800); return () => clearTimeout(t); }, [onDone]);
  return (
    <div style={{
      position: "fixed", left: x, top: y,
      transform: "translateX(-50%)",
      zIndex: 9000, pointerEvents: "none",
      animation: "healFloat 1.8s ease-out forwards",
      display: "flex", alignItems: "center", gap: 5,
      background: `${RC[item.rarity]?.color || "#888"}22`,
      border: `1.5px solid ${RC[item.rarity]?.color || "#888"}55`,
      borderRadius: 20, padding: "5px 10px",
      backdropFilter: "blur(8px)",
      boxShadow: `0 0 16px ${RC[item.rarity]?.color || "#888"}44`,
    }}>
      <span style={{ fontSize: 18 }}>{item.emoji}</span>
      <span style={{ fontFamily: T.fontD, color: RC[item.rarity]?.color || "#aaa", fontSize: 11 }}>
        {item.name}!
      </span>
    </div>
  );
};
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 9
// ACHIEVEMENTS · COMBO COUNTER · BATTLE ENHANCEMENTS
// STATUS EFFECT VISUALS · ENEMY STAGGER · HIT SPARKS
// ═══════════════════════════════════════════════════════════════

// ─── Achievement definitions ───────────────────────────────────
export const ACHIEVEMENTS = {
  first_battle:   { id: "first_battle",   name: "Battle Born",      emoji: "⚔️",  desc: "Win your first battle.",              condition: s => (s.player?.battlesWon || 0) >= 1 },
  rich:           { id: "rich",           name: "Treasure Hunter",  emoji: "💰",  desc: "Collect 1000 gold total.",            condition: s => (s.player?.totalGold || 0) >= 1000 },
  scholar:        { id: "scholar",        name: "Finance Scholar",  emoji: "📚",  desc: "Answer 10 finance questions.",        condition: s => (s.totalFinanceAnswered || 0) >= 10 },
  streak_3:       { id: "streak_3",       name: "On a Roll!",       emoji: "🔥",  desc: "Answer 3 in a row correctly.",        condition: s => (s.financeStreakBest || 0) >= 3 },
  streak_5:       { id: "streak_5",       name: "Unstoppable!",     emoji: "⚡",  desc: "Answer 5 in a row correctly.",        condition: s => (s.financeStreakBest || 0) >= 5 },
  tamer:          { id: "tamer",          name: "Pet Whisperer",    emoji: "🐾",  desc: "Tame your first monster.",            condition: s => (s.tamedCount || 0) >= 1 },
  explorer:       { id: "explorer",       name: "Zone Explorer",    emoji: "🗺️",  desc: "Visit 2 different zones.",            condition: s => (s.player?.unlockedZones?.length || 0) >= 2 },
  dungeon_reach:  { id: "dungeon_reach",  name: "Dungeon Delver",   emoji: "🗡️",  desc: "Reach the Shadow Dungeon.",           condition: s => (s.player?.unlockedZones || []).includes("0_-2") },
  level_5:        { id: "level_5",        name: "Rising Hero",      emoji: "🌟",  desc: "Reach level 5.",                      condition: s => (s.player?.level || 1) >= 5 },
  level_10:       { id: "level_10",       name: "Veteran",          emoji: "🏆",  desc: "Reach level 10.",                     condition: s => (s.player?.level || 1) >= 10 },
  spellcaster:    { id: "spellcaster",    name: "Spellcaster",      emoji: "✨",  desc: "Cast 20 spells.",                     condition: s => (s.player?.spellsCast || 0) >= 20 },
  chest_hunter:   { id: "chest_hunter",  name: "Chest Hunter",     emoji: "📦",  desc: "Open 5 treasure chests.",             condition: s => (s.chestsOpened || 0) >= 5 },
};

// ─── Achievement popup ─────────────────────────────────────────
export const AchievementPopup = ({ achievement, onDone }) => {
  useEffect(() => { const t = setTimeout(onDone, 4000); return () => clearTimeout(t); }, [onDone]);
  return (
    <div style={{
      position: "fixed", bottom: 90, right: 16,
      background: "linear-gradient(145deg, #1a1230, #2a1d45)",
      border: `2px solid ${T.gold}`,
      borderRadius: 18,
      padding: "12px 16px",
      display: "flex", alignItems: "center", gap: 12,
      boxShadow: `0 0 32px ${T.goldGlow}, 0 8px 32px rgba(0,0,0,.7)`,
      animation: "slideInRight .4s cubic-bezier(.4,0,.2,1)",
      zIndex: 99990, maxWidth: 320, pointerEvents: "none",
    }}>
      {/* Gold shimmer strip */}
      <div style={{
        position: "absolute", top: 0, left: 0, right: 0, height: 2,
        background: `linear-gradient(90deg, transparent, ${T.gold}, transparent)`,
        borderRadius: "18px 18px 0 0",
      }} />

      <div style={{
        width: 48, height: 48, borderRadius: "50%",
        background: `radial-gradient(circle, ${T.gold}33, ${T.gold}11)`,
        border: `2px solid ${T.gold}66`,
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 24, flexShrink: 0,
        animation: "pulseGold 1.5s ease-in-out infinite",
      }}>
        {achievement.emoji}
      </div>

      <div>
        <div style={{ fontFamily: T.fontD, color: T.gold, fontSize: 10, letterSpacing: 1.5, marginBottom: 2 }}>
          🏆 ACHIEVEMENT UNLOCKED
        </div>
        <div style={{ fontFamily: T.fontD, color: "#fff", fontSize: 13 }}>
          {achievement.name}
        </div>
        <div style={{ fontFamily: T.fontB, color: "#888", fontSize: 10 }}>
          {achievement.desc}
        </div>
      </div>
    </div>
  );
};

// ─── Achievement tracker hook ──────────────────────────────────
export function useAchievements(state) {
  const [unlocked, setUnlocked] = useState(() => {
    try { return new Set(JSON.parse(localStorage.getItem("sq_achievements") || "[]")); }
    catch { return new Set(); }
  });
  const [queue, setQueue] = useState([]);

  useEffect(() => {
    if (!state.player) return;
    const newlyUnlocked = Object.values(ACHIEVEMENTS).filter(a =>
      !unlocked.has(a.id) && a.condition(state)
    );
    if (!newlyUnlocked.length) return;
    const newSet = new Set([...unlocked, ...newlyUnlocked.map(a => a.id)]);
    setUnlocked(newSet);
    setQueue(q => [...q, ...newlyUnlocked]);
    try { localStorage.setItem("sq_achievements", JSON.stringify([...newSet])); } catch {}
  }, [state.player?.battlesWon, state.player?.totalGold, state.totalFinanceAnswered,
      state.financeStreakBest, state.tamedCount, state.player?.level,
      state.player?.spellsCast, state.chestsOpened, state.player?.unlockedZones?.length]);

  const dismiss = useCallback(() => setQueue(q => q.slice(1)), []);
  return { unlocked, currentAchievement: queue[0] || null, dismiss };
}

// ═══════════════════════════════════════════════════════════════
// COMBO COUNTER — shows during battle on consecutive hits
// ═══════════════════════════════════════════════════════════════
export const ComboCounter = ({ combo }) => {
  if (combo < 2) return null;
  const colors = ["", "", "#FFD700", "#FF9800", "#FF5722", "#F44336", "#E91E63", "#9C27B0"];
  const color = colors[Math.min(combo, colors.length - 1)] || "#7C4DFF";
  const size = Math.min(32, 18 + combo * 2);

  return (
    <div style={{
      position: "absolute", top: "28%", left: "50%",
      transform: "translate(-50%, -50%)",
      fontFamily: T.fontD, fontSize: size,
      color,
      textShadow: `0 0 20px ${color}, 0 0 40px ${color}`,
      animation: "popIn .2s ease",
      pointerEvents: "none", zIndex: 9200,
      letterSpacing: 2,
    }}>
      {combo}× COMBO!
      {combo >= 5 && (
        <div style={{ fontSize: 12, textAlign: "center", color: T.gold, animation: "glowPulse 1s infinite" }}>
          🔥 ON FIRE!
        </div>
      )}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// BATTLE STREAK BONUS DISPLAY
// ═══════════════════════════════════════════════════════════════
export const BattleStreakBonus = ({ streak }) => {
  if (streak < 2) return null;
  const bonusPct = Math.min(50, (streak - 1) * 10);
  return (
    <div style={{
      position: "absolute", top: 56, left: "50%", transform: "translateX(-50%)",
      background: "rgba(0,0,0,.7)", backdropFilter: "blur(8px)",
      border: `1px solid ${T.orange}55`, borderRadius: 12,
      padding: "4px 12px",
      display: "flex", alignItems: "center", gap: 6,
      pointerEvents: "none", zIndex: 8500, animation: "slideDown .3s ease",
    }}>
      <span style={{ fontSize: 14 }}>🔥</span>
      <span style={{ fontFamily: T.fontD, color: T.orange, fontSize: 11 }}>
        Battle Streak ×{streak}
      </span>
      <Badge label={`+${bonusPct}% XP`} color={T.greenL} bg={`${T.greenL}18`} />
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// STATUS EFFECT FLOATING ICONS (world screen, above player)
// ═══════════════════════════════════════════════════════════════
export const StatusEffectFloaters = ({ effects = [], x, y }) => {
  if (!effects.length) return null;
  return (
    <div style={{
      position: "absolute", left: x, top: y - 40,
      transform: "translateX(-50%)",
      display: "flex", gap: 4,
      pointerEvents: "none", zIndex: 8100,
    }}>
      {effects.map((fx, i) => (
        <div key={fx.id} style={{
          fontSize: 14,
          animation: `floatIdle ${1.5 + i * 0.3}s ease-in-out ${i * 0.2}s infinite`,
          filter: `drop-shadow(0 0 4px ${fx.color})`,
        }}>
          {fx.emoji}
        </div>
      ))}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// HIT SPARK VFX — plays on enemy during PET_HIT phase
// ═══════════════════════════════════════════════════════════════
export const HitSpark = ({ color = T.gold, x = "60%", y = "30%", active }) => {
  if (!active) return null;
  const sparks = useMemo(() => Array.from({ length: 12 }, (_, i) => {
    const angle = (i / 12) * Math.PI * 2;
    const dist = 20 + Math.random() * 30;
    return { id: i, tx: `${Math.cos(angle) * dist}px`, ty: `${Math.sin(angle) * dist}px`, delay: i * 0.02, size: 4 + Math.random() * 5 };
  }), []);

  return (
    <div style={{ position: "absolute", left: x, top: y, pointerEvents: "none", zIndex: 9600 }}>
      {/* Central flash */}
      <div style={{
        position: "absolute", transform: "translate(-50%,-50%)",
        width: 40, height: 40, borderRadius: "50%",
        background: `radial-gradient(circle, ${color}bb 0%, transparent 70%)`,
        animation: "castRelease .3s ease forwards",
      }} />
      {/* Impact lines */}
      {sparks.map(s => (
        <div key={s.id} style={{
          position: "absolute", width: s.size, height: s.size,
          borderRadius: "50%", background: color,
          boxShadow: `0 0 ${s.size * 2}px ${color}`,
          "--tx": s.tx, "--ty": s.ty,
          animation: `particleFly .4s ease ${s.delay}s forwards`,
          transform: "translate(-50%,-50%)",
        }} />
      ))}
      {/* Star burst */}
      {["✦", "✧", "✦"].map((c, i) => (
        <div key={i} style={{
          position: "absolute", transform: `translate(-50%,-50%) rotate(${i * 60}deg)`,
          color, fontSize: 16, fontFamily: T.fontD,
          animation: `particleFly .5s ease ${i * 0.06}s forwards`,
          "--tx": `${Math.cos(i * 2.1) * 40}px`,
          "--ty": `${Math.sin(i * 2.1) * 40}px`,
        }}>
          {c}
        </div>
      ))}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// SPELL VFX OVERLAY — maps spell vfx to visual effect
// ═══════════════════════════════════════════════════════════════
const VFX_CONFIGS = {
  fire:     { color: "#FF6B35", particles: 20, emoji: "🔥", trail: true },
  ice:      { color: "#80DEEA", particles: 16, emoji: "❄️", trail: false },
  earth:    { color: "#8D6E63", particles: 18, emoji: "🪨", trail: false },
  water:    { color: "#29B6F6", particles: 22, emoji: "🌊", trail: true },
  lightning:{ color: "#FFD600", particles: 24, emoji: "⚡", trail: true },
  sparkle:  { color: "#CE93D8", particles: 14, emoji: "✨", trail: false },
  heal:     { color: "#69F0AE", particles: 12, emoji: "💚", trail: false },
  nova:     { color: "#CE93D8", particles: 30, emoji: "🌟", trail: true },
  meteor:   { color: "#FF5722", particles: 28, emoji: "☄️", trail: true },
  storm:    { color: "#FFF176", particles: 26, emoji: "🌪️", trail: true },
  thunder:  { color: "#FFD600", particles: 22, emoji: "⚡", trail: true },
  blizzard: { color: "#B3E5FC", particles: 20, emoji: "🌨️", trail: false },
  vortex:   { color: "#0288D1", particles: 24, emoji: "🌀", trail: true },
  rock:     { color: "#A1887F", particles: 16, emoji: "🪨", trail: false },
  permafrost:{ color: "#B3E5FC", particles: 26, emoji: "🧊", trail: false },
  grand_heal:{ color: "#FFEE58", particles: 18, emoji: "✨", trail: false },
};

export const SpellVFXOverlay = ({ spellId, phase, onComplete }) => {
  const sp = SPELLS[spellId];
  if (!sp || !["CAST_CHARGE", "CAST_RELEASE"].includes(phase)) return null;
  const vfxKey = sp.vfx || "sparkle";
  const vfx = VFX_CONFIGS[vfxKey] || VFX_CONFIGS.sparkle;

  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 9100 }}>
      {/* Orb rising from player toward enemy */}
      {phase === "CAST_RELEASE" && (
        <div style={{
          position: "absolute", left: "22%", top: "35%",
          fontSize: 36,
          animation: "petCharge .44s cubic-bezier(.4,0,.2,1) forwards",
          filter: `drop-shadow(0 0 16px ${vfx.color})`,
        }}>
          {vfx.emoji}
        </div>
      )}
      {/* Charging aura */}
      {phase === "CAST_CHARGE" && (
        <>
          <div style={{
            position: "absolute", left: "16%", top: "20%",
            width: 80, height: 80, borderRadius: "50%",
            background: `radial-gradient(circle, ${vfx.color}44 0%, transparent 70%)`,
            animation: "castCharge .7s ease forwards",
          }} />
          {Array.from({ length: 8 }, (_, i) => (
            <div key={i} style={{
              position: "absolute", left: "16%", top: "30%",
              fontSize: 18,
              "--tx": `${Math.cos(i / 8 * Math.PI * 2) * 55}px`,
              "--ty": `${Math.sin(i / 8 * Math.PI * 2) * 40}px`,
              animation: `orbitOrb ${0.8 + i * 0.1}s linear ${i * 0.05}s infinite`,
              transformOrigin: "0 0",
            }}>
              {vfx.emoji}
            </div>
          ))}
        </>
      )}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// ENEMY STAGGER — flashes enemy on damage
// ═══════════════════════════════════════════════════════════════
export const EnemyStaggerEffect = ({ active, color }) => {
  if (!active) return null;
  return (
    <div style={{
      position: "absolute", inset: 0,
      background: `radial-gradient(circle at 70% 40%, ${color}44 0%, transparent 60%)`,
      pointerEvents: "none", zIndex: 9300,
      animation: "enemyHit .26s ease forwards",
    }} />
  );
};

// ═══════════════════════════════════════════════════════════════
// FLOATING BATTLE TEXT (for buff/debuff announcements)
// ═══════════════════════════════════════════════════════════════
export const BattleText = ({ text, color = "#fff", x = "50%", y = "50%", onDone }) => {
  useEffect(() => { const t = setTimeout(onDone, 1200); return () => clearTimeout(t); }, [onDone]);
  return (
    <div style={{
      position: "absolute", left: x, top: y,
      transform: "translate(-50%, -50%)",
      fontFamily: T.fontD, fontSize: 16, color,
      textShadow: `0 0 16px ${color}`,
      animation: "dmgFloat 1.2s ease-out forwards",
      pointerEvents: "none", zIndex: 9800,
      whiteSpace: "nowrap",
    }}>
      {text}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// PRODIGY-STYLE BATTLE TIMER (limits turn thinking time)
// ═══════════════════════════════════════════════════════════════
export const BattleTurnTimer = ({ active, duration = 30, onExpire }) => {
  const [timeLeft, setTimeLeft] = useState(duration);

  useEffect(() => {
    if (!active) { setTimeLeft(duration); return; }
    const t = setInterval(() => {
      setTimeLeft(s => {
        if (s <= 1) { clearInterval(t); onExpire?.(); return duration; }
        return s - 1;
      });
    }, 1000);
    return () => clearInterval(t);
  }, [active, duration, onExpire]);

  if (!active) return null;
  const pct = (timeLeft / duration) * 100;
  const color = pct > 50 ? T.green : pct > 25 ? "#FF9800" : T.red;

  return (
    <div style={{
      position: "absolute", top: 8, left: "50%", transform: "translateX(-50%)",
      display: "flex", alignItems: "center", gap: 8, zIndex: 8600,
      pointerEvents: "none",
    }}>
      <div style={{
        width: 140, height: 6, background: "rgba(0,0,0,.5)",
        borderRadius: 999, overflow: "hidden",
        border: "1px solid rgba(255,255,255,.1)",
      }}>
        <div style={{
          height: "100%", width: `${pct}%`, background: color,
          borderRadius: 999, transition: "width 1s linear, background .5s ease",
          boxShadow: `0 0 8px ${color}`,
        }} />
      </div>
      <div style={{
        fontFamily: T.fontD, fontSize: 12, color,
        animation: timeLeft <= 5 ? "glowPulse .5s ease-in-out infinite" : "none",
      }}>
        {timeLeft}s
      </div>
    </div>
  );
};
// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — BLOCK 10
// WORLD MAP SCREEN · DAILY CHALLENGES · ZONE PREVIEW
// ENHANCED NPC DIALOGUE · WORLD EVENT SYSTEM
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// WORLD MAP OVERVIEW SCREEN (zoom-out map à la Prodigy)
// ═══════════════════════════════════════════════════════════════
const ZONE_MAP_POSITIONS = {
  "0_0":  { x: 50, y: 65, name: "Brightfield Town",  emoji: "🏘️", tier: 1, color: "#4CAF50" },
  "0_-1": { x: 50, y: 40, name: "Whispering Woods",  emoji: "🌲", tier: 2, color: "#2E7D32" },
  "0_-2": { x: 50, y: 18, name: "Shadow Dungeon",    emoji: "🗡️", tier: 3, color: "#7C4DFF" },
};

const ZONE_CONNECTIONS = [
  { from: "0_0", to: "0_-1" },
  { from: "0_-1", to: "0_-2" },
];

export const WorldMapScreen = ({ player, questProgress, onClose }) => {
  const [hoveredZone, setHoveredZone] = useState(null);
  const unlocked = new Set(player.unlockedZones || ["0_0"]);

  return (
    <>
      <div style={{
        position: "fixed", inset: 0, background: "rgba(0,0,0,.9)",
        backdropFilter: "blur(8px)", zIndex: 9600, pointerEvents: "auto",
      }} onClick={onClose} />

      <div className="modal-stone" style={{
        width: "min(680px, 96vw)", maxHeight: "90vh",
        display: "flex", flexDirection: "column",
        animation: "popInCenter .3s ease", zIndex: 9601,
        overflow: "hidden",
      }}>
        {/* Header */}
        <div style={{
          padding: "16px 20px 12px",
          borderBottom: "1px solid rgba(255,255,255,.08)",
          display: "flex", alignItems: "center", justifyContent: "space-between",
        }}>
          <div style={{ fontFamily: T.fontD, fontSize: 20, color: T.gold }}>
            🗺️ World Map
          </div>
          <button className="gbtn" onClick={onClose} style={{
            padding: "4px 12px", fontSize: 11, borderRadius: 10,
            background: "rgba(255,255,255,.07)", border: "1px solid rgba(255,255,255,.12)",
            color: "#666", fontFamily: T.fontD,
          }}>✕</button>
        </div>

        {/* Map canvas */}
        <div style={{ position: "relative", flex: 1, minHeight: 360, padding: 20 }}>

          {/* Background gradient (stylized overworld) */}
          <div style={{
            position: "absolute", inset: 20, borderRadius: 18,
            background: "linear-gradient(180deg, #0a1628 0%, #1a3a1a 40%, #2d5a1e 70%, #4a8a2c 100%)",
            border: "2px solid rgba(255,255,255,.06)",
            overflow: "hidden",
          }}>
            {/* Decorative terrain features */}
            <div style={{ position: "absolute", bottom: "8%", left: "5%", right: "5%", height: "35%",
              background: "linear-gradient(0deg, #4a8a2c, #3d7a24)", borderRadius: "50% 50% 0 0" }} />
            <div style={{ position: "absolute", top: "5%", left: "10%", right: "10%", height: "45%",
              background: "linear-gradient(0deg, #0a1628, #12243c)", borderRadius: "0 0 50% 50%" }} />
            {/* Grid lines */}
            {Array.from({ length: 8 }, (_, i) => (
              <div key={`h${i}`} style={{
                position: "absolute", top: `${i * 12.5}%`, left: 0, right: 0,
                height: 1, background: "rgba(255,255,255,.03)",
              }} />
            ))}
          </div>

          {/* Connection paths */}
          <svg style={{ position: "absolute", inset: 20, pointerEvents: "none", zIndex: 2 }} width="100%" height="100%">
            {ZONE_CONNECTIONS.map(({ from, to }) => {
              const a = ZONE_MAP_POSITIONS[from];
              const b = ZONE_MAP_POSITIONS[to];
              if (!a || !b) return null;
              const unlkA = unlocked.has(from);
              const unlkB = unlocked.has(to);
              return (
                <g key={`${from}-${to}`}>
                  <line
                    x1={`${a.x}%`} y1={`${a.y}%`}
                    x2={`${b.x}%`} y2={`${b.y}%`}
                    stroke={unlkA && unlkB ? T.gold : "rgba(255,255,255,.2)"}
                    strokeWidth={unlkA && unlkB ? 3 : 1.5}
                    strokeDasharray={unlkA && unlkB ? "none" : "6,4"}
                    opacity={0.6}
                  />
                  {/* Path dots */}
                  {Array.from({ length: 4 }, (_, i) => {
                    const t2 = (i + 1) / 5;
                    const px = a.x + (b.x - a.x) * t2;
                    const py = a.y + (b.y - a.y) * t2;
                    return (
                      <circle key={i} cx={`${px}%`} cy={`${py}%`} r={3}
                        fill={unlkA && unlkB ? T.gold : "#444"} opacity={0.5} />
                    );
                  })}
                </g>
              );
            })}
          </svg>

          {/* Zone nodes */}
          {Object.entries(ZONE_MAP_POSITIONS).map(([zKey, zPos]) => {
            const isUnlocked = unlocked.has(zKey);
            const isCurrent = `${player.zx}_${player.zy}` === zKey;
            const isHovered = hoveredZone === zKey;
            const zm = getZoneMeta(...zKey.split("_").map(Number));
            const questsDone = QUESTS.filter(q =>
              questProgress[q.id]?.claimed &&
              (q.goal.type === "zone" && q.goal.zx === parseInt(zKey.split("_")[0]) && q.goal.zy === parseInt(zKey.split("_")[1]))
            ).length;

            return (
              <div key={zKey}
                onMouseEnter={() => setHoveredZone(zKey)}
                onMouseLeave={() => setHoveredZone(null)}
                style={{
                  position: "absolute",
                  left: `calc(${zPos.x}% + 20px)`, top: `calc(${zPos.y}% + 20px)`,
                  transform: "translate(-50%, -50%)",
                  zIndex: 10, cursor: isUnlocked ? "pointer" : "not-allowed",
                }}>

                {/* Zone circle */}
                <div style={{
                  width: isCurrent ? 72 : 56, height: isCurrent ? 72 : 56,
                  borderRadius: "50%",
                  background: isUnlocked
                    ? `radial-gradient(circle, ${zPos.color}44 0%, ${zPos.color}22 100%)`
                    : "rgba(40,40,40,.8)",
                  border: `3px solid ${isCurrent ? T.gold : isUnlocked ? zPos.color : "#333"}`,
                  display: "flex", flexDirection: "column",
                  alignItems: "center", justifyContent: "center",
                  transition: "all .2s ease",
                  boxShadow: isCurrent
                    ? `0 0 24px ${T.gold}88, 0 0 48px ${T.gold}44`
                    : isHovered && isUnlocked
                    ? `0 0 18px ${zPos.color}66`
                    : "none",
                  animation: isCurrent ? "pulseGold 1.5s ease-in-out infinite" : "none",
                }}>
                  <span style={{ fontSize: isCurrent ? 26 : 22, filter: isUnlocked ? "none" : "grayscale(1) opacity(.4)" }}>
                    {zPos.emoji}
                  </span>
                  <div style={{ fontFamily: T.fontD, fontSize: 9, color: isUnlocked ? zPos.color : "#444", marginTop: 1 }}>
                    T{zPos.tier}
                  </div>
                </div>

                {/* Current player indicator */}
                {isCurrent && (
                  <div style={{
                    position: "absolute", top: -20, left: "50%", transform: "translateX(-50%)",
                    fontFamily: T.fontD, fontSize: 10, color: T.gold,
                    animation: "floatIdle 1.5s ease-in-out infinite",
                    whiteSpace: "nowrap",
                    textShadow: `0 0 12px ${T.gold}`,
                  }}>
                    ▼ You are here
                  </div>
                )}

                {/* Lock icon */}
                {!isUnlocked && (
                  <div style={{
                    position: "absolute", top: -4, right: -4,
                    background: "#1a1a2e", border: "1px solid #333",
                    borderRadius: "50%", width: 18, height: 18,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 10,
                  }}>🔒</div>
                )}

                {/* Zone label */}
                <div style={{
                  position: "absolute", top: "100%", left: "50%",
                  transform: "translateX(-50%)", marginTop: 6,
                  textAlign: "center", whiteSpace: "nowrap",
                }}>
                  <div style={{ fontFamily: T.fontD, fontSize: 10, color: isUnlocked ? "#fff" : "#444" }}>
                    {zPos.name}
                  </div>
                </div>

                {/* Hover tooltip */}
                {isHovered && isUnlocked && (
                  <div style={{
                    position: "absolute", bottom: "110%", left: "50%",
                    transform: "translateX(-50%)",
                    background: "rgba(8,5,20,.97)",
                    border: `1.5px solid ${zPos.color}44`,
                    borderRadius: 12, padding: "8px 14px",
                    minWidth: 160, textAlign: "center",
                    boxShadow: `0 4px 20px rgba(0,0,0,.8)`,
                    animation: "slideDown .15s ease",
                    zIndex: 20,
                  }}>
                    <div style={{ fontFamily: T.fontD, color: zPos.color, fontSize: 13, marginBottom: 4 }}>
                      {zPos.name}
                    </div>
                    <div style={{ display: "flex", gap: 6, justifyContent: "center", flexWrap: "wrap" }}>
                      <Badge label={`Tier ${zPos.tier}`} color={zPos.color} />
                      {(zm?.validMonsters || []).slice(0, 3).map(id =>
                        <span key={id} style={{ fontSize: 14 }}>{BESTIARY[id]?.emoji}</span>
                      )}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Legend */}
        <div style={{
          padding: "10px 20px 16px",
          borderTop: "1px solid rgba(255,255,255,.06)",
          display: "flex", gap: 14, justifyContent: "center", flexWrap: "wrap",
        }}>
          {[
            { icon: "🟡", label: "Current Zone" },
            { icon: "🟢", label: "Unlocked" },
            { icon: "🔒", label: "Locked" },
            { icon: "▼",  label: "Your Position", color: T.gold },
          ].map(({ icon, label, color }) => (
            <div key={label} style={{ display: "flex", alignItems: "center", gap: 5 }}>
              <span style={{ fontSize: 12, color: color || "#888" }}>{icon}</span>
              <span style={{ fontFamily: T.fontB, fontSize: 10, color: "#666" }}>{label}</span>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

// ═══════════════════════════════════════════════════════════════
// DAILY CHALLENGE SYSTEM
// ═══════════════════════════════════════════════════════════════
const DAILY_CHALLENGES = [
  { id: "dc1", desc: "Win 3 battles today",         goal: { type: "battles",   n: 3 }, reward: { gold: 80,  xp: 120 } },
  { id: "dc2", desc: "Answer 5 finance questions",  goal: { type: "financeQ",  n: 5 }, reward: { gold: 100, xp: 150 } },
  { id: "dc3", desc: "Open 2 treasure chests",      goal: { type: "chests",    n: 2 }, reward: { gold: 60,  xp: 80  } },
  { id: "dc4", desc: "Cast 8 spells in battle",     goal: { type: "spells",    n: 8 }, reward: { gold: 90,  xp: 130 } },
  { id: "dc5", desc: "Earn 200 gold from battles",  goal: { type: "totalGold", n: 200 }, reward: { gold: 75, xp: 100 } },
];

function getDailyChallenge() {
  const dayKey = new Date().toDateString();
  const storedKey = localStorage.getItem("sq_daily_key");
  let stored = null;
  try { stored = JSON.parse(localStorage.getItem("sq_daily_challenge") || "null"); } catch {}
  if (storedKey === dayKey && stored) return stored;
  const ch = DAILY_CHALLENGES[Math.floor(Math.random() * DAILY_CHALLENGES.length)];
  const newChallenge = { ...ch, progress: 0, claimed: false, date: dayKey };
  localStorage.setItem("sq_daily_key", dayKey);
  localStorage.setItem("sq_daily_challenge", JSON.stringify(newChallenge));
  return newChallenge;
}

export const DailyChallengeCard = ({ state, dispatch }) => {
  const [challenge, setChallenge] = useState(getDailyChallenge);
  const [expanded, setExpanded] = useState(false);

  // Sync progress from game state
  useEffect(() => {
    if (!state.player) return;
    const g = challenge.goal;
    let progress = challenge.progress;
    if (g.type === "battles")   progress = state.player.battlesWon  || 0;
    if (g.type === "financeQ")  progress = state.totalFinanceAnswered || 0;
    if (g.type === "chests")    progress = state.chestsOpened || 0;
    if (g.type === "spells")    progress = state.player.spellsCast || 0;
    if (g.type === "totalGold") progress = state.player.totalGold || 0;
    const capped = Math.min(progress, g.n);
    if (capped !== challenge.progress) {
      const updated = { ...challenge, progress: capped };
      setChallenge(updated);
      try { localStorage.setItem("sq_daily_challenge", JSON.stringify(updated)); } catch {}
    }
  }, [state.player?.battlesWon, state.totalFinanceAnswered, state.chestsOpened,
      state.player?.spellsCast, state.player?.totalGold]);

  const done = challenge.progress >= challenge.goal.n;
  const pct = Math.min(100, (challenge.progress / challenge.goal.n) * 100);

  const claimReward = () => {
    if (!done || challenge.claimed) return;
    dispatch({ type: "BUY_ITEM", payload: { itemId: "hp_pot" } }); // placeholder
    dispatch({ type: "SET_TOAST", payload: { msg: `🌟 Daily: +${challenge.reward.gold}g +${challenge.reward.xp}xp!`, t: "victory" } });
    const updated = { ...challenge, claimed: true };
    setChallenge(updated);
    try { localStorage.setItem("sq_daily_challenge", JSON.stringify(updated)); } catch {}
  };

  return (
    <div className="hud-interactive" style={{
      position: "absolute", top: 12, left: "50%", transform: "translateX(-50%)",
      zIndex: 8005,
    }}>
      <button className="gbtn" onClick={() => setExpanded(e => !e)} style={{
        background: done ? `${T.greenL}14` : "rgba(6,4,18,.88)",
        border: `1.5px solid ${done ? T.greenL : "rgba(255,215,0,.22)"}`,
        borderRadius: 14, padding: "5px 14px",
        display: "flex", alignItems: "center", gap: 7,
        backdropFilter: "blur(12px)",
        boxShadow: done ? `0 0 16px ${T.greenL}33` : "none",
        color: "#fff",
      }}>
        <span style={{ fontSize: 14 }}>🌟</span>
        <span style={{ fontFamily: T.fontD, fontSize: 10, color: done ? T.greenL : T.gold }}>
          Daily
        </span>
        <div style={{
          width: 50, height: 4, background: "rgba(255,255,255,.1)",
          borderRadius: 999, overflow: "hidden",
        }}>
          <div style={{
            height: "100%", width: `${pct}%`,
            background: done ? T.greenL : T.gold,
            borderRadius: 999, transition: "width .5s ease",
          }} />
        </div>
        <span style={{ fontFamily: T.fontB, fontSize: 9, color: "#888" }}>
          {challenge.progress}/{challenge.goal.n}
        </span>
      </button>

      {expanded && (
        <div style={{
          position: "absolute", top: "100%", left: "50%", transform: "translateX(-50%)",
          marginTop: 6, background: "rgba(6,4,18,.97)",
          border: "1.5px solid rgba(255,215,0,.2)", borderRadius: 14,
          padding: "12px 16px", minWidth: 220, animation: "slideDown .2s ease",
          backdropFilter: "blur(16px)", zIndex: 10,
          boxShadow: "0 8px 32px rgba(0,0,0,.8)",
        }}>
          <div style={{ fontFamily: T.fontD, color: T.gold, fontSize: 12, marginBottom: 6 }}>
            🌟 Daily Challenge
          </div>
          <div style={{ fontFamily: T.fontB, color: "#ccc", fontSize: 11, marginBottom: 8 }}>
            {challenge.desc}
          </div>
          <div style={{ marginBottom: 8 }}>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 9, color: "#666", marginBottom: 3 }}>
              <span>{challenge.progress}/{challenge.goal.n}</span>
              <span>{Math.round(pct)}%</span>
            </div>
            <StatBar val={challenge.progress} max={challenge.goal.n} color={done ? T.greenL : T.gold} h={6} />
          </div>
          <div style={{ display: "flex", gap: 6, marginBottom: done && !challenge.claimed ? 10 : 0 }}>
            <Badge label={`+${challenge.reward.gold}g`} color={T.gold} />
            <Badge label={`+${challenge.reward.xp}xp`} color="#CE93D8" />
          </div>
          {done && !challenge.claimed && (
            <button className="gbtn" onClick={claimReward} style={{
              width: "100%", padding: "7px", fontSize: 12, borderRadius: 10,
              background: `linear-gradient(135deg,${T.green},${T.greenD})`,
              color: "#fff", border: "none", fontFamily: T.fontD,
              animation: "pulseGreen 1.5s ease-in-out infinite",
            }}>
              Claim Reward!
            </button>
          )}
          {challenge.claimed && (
            <div style={{ textAlign: "center", color: T.greenL, fontFamily: T.fontD, fontSize: 11 }}>
              ✓ Claimed! Come back tomorrow.
            </div>
          )}
        </div>
      )}
    </div>
  );
};

// ═══════════════════════════════════════════════════════════════
// WORLD EVENTS (random timed events like "Gold Rush!" or "Monster Surge")
// ═══════════════════════════════════════════════════════════════
const WORLD_EVENTS = [
  { id: "gold_rush",     name: "💰 Gold Rush!",      desc: "All chests give 2× gold for 60s!",    duration: 60,  color: T.gold   },
  { id: "monster_surge", name: "👾 Monster Surge!",  desc: "More monsters, 1.5× XP for 45s!",    duration: 45,  color: "#EF5350" },
  { id: "finance_bonus", name: "📊 Finance Bonus!",  desc: "Correct answers give 2× multiplier!", duration: 90,  color: T.blue   },
  { id: "pet_power",     name: "🐾 Pet Power Hour!", desc: "Pets deal 2× damage this battle!",    duration: 60,  color: T.purple },
];

export const WorldEventBanner = ({ event, timeLeft }) => {
  if (!event) return null;
  const pct = (timeLeft / event.duration) * 100;
  return (
    <div style={{
      position: "absolute", top: 56, left: "50%", transform: "translateX(-50%)",
      background: "rgba(6,4,18,.94)",
      border: `2px solid ${event.color}`,
      borderRadius: 20, padding: "8px 18px",
      display: "flex", alignItems: "center", gap: 12,
      boxShadow: `0 0 24px ${event.color}44`,
      animation: "slideDown .35s ease",
      pointerEvents: "none", zIndex: 8020,
      backdropFilter: "blur(14px)",
    }}>
      <div>
        <div style={{ fontFamily: T.fontD, color: event.color, fontSize: 13 }}>{event.name}</div>
        <div style={{ fontFamily: T.fontB, color: "#888", fontSize: 10 }}>{event.desc}</div>
      </div>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
        <div style={{
          width: 60, height: 4, background: "rgba(255,255,255,.1)",
          borderRadius: 999, overflow: "hidden",
        }}>
          <div style={{
            height: "100%", width: `${pct}%`, background: event.color,
            borderRadius: 999, transition: "width 1s linear",
          }} />
        </div>
        <div style={{ fontFamily: T.fontD, color: event.color, fontSize: 10 }}>
          {timeLeft}s
        </div>
      </div>
    </div>
  );
};

export function useWorldEvent(tick) {
  const [event, setEvent] = useState(null);
  const [timeLeft, setTimeLeft] = useState(0);

  useEffect(() => {
    if (!event) return;
    if (timeLeft <= 0) { setEvent(null); return; }
    const t = setTimeout(() => setTimeLeft(s => s - 1), 1000);
    return () => clearTimeout(t);
  }, [tick, timeLeft, event]);

  useEffect(() => {
    // Random chance every 3 min to trigger a world event
    const t = setInterval(() => {
      if (event) return;
      if (Math.random() > 0.15) return;
      const ev = WORLD_EVENTS[Math.floor(Math.random() * WORLD_EVENTS.length)];
      setEvent(ev);
      setTimeLeft(ev.duration);
    }, 30000);
    return () => clearInterval(t);
  }, [event]);

  return { event, timeLeft };
}

// ═══════════════════════════════════════════════════════════════
// ZONE TRANSITION FLAVOR TEXT
// ═══════════════════════════════════════════════════════════════
const ZONE_FLAVOR = {
  "0_0":  ["A warm breeze sweeps through Brightfield Town.", "Merchants call out from every corner.", "The fountain glimmers in the sun."],
  "0_-1": ["Shadows stretch long between the ancient trees.", "Strange rustling echoes from the undergrowth.", "The air smells of pine and something… older."],
  "0_-2": ["The darkness here feels alive.", "Ancient runes pulse on the dungeon walls.", "Even the torches seem afraid to burn brightly."],
};

export const ZoneFlavorToast = ({ zx, zy }) => {
  const [text, setText] = useState(null);
  useEffect(() => {
    const key = `${zx}_${zy}`;
    const lines = ZONE_FLAVOR[key] || ["You enter an unknown region."];
    const line = lines[Math.floor(Math.random() * lines.length)];
    setText(line);
    const t = setTimeout(() => setText(null), 3500);
    return () => clearTimeout(t);
  }, [zx, zy]);

  if (!text) return null;
  const tier = getZoneTier(zx, zy);
  const color = tier === 1 ? T.greenL : tier === 2 ? "#CE93D8" : "#EF5350";

  return (
    <div style={{
      position: "fixed", bottom: 100, left: "50%", transform: "translateX(-50%)",
      background: "rgba(6,4,18,.94)", backdropFilter: "blur(12px)",
      border: `1.5px solid ${color}44`, borderRadius: 20,
      padding: "10px 22px", zIndex: 8900, pointerEvents: "none",
      fontFamily: T.fontB, fontSize: 13, color: "rgba(255,255,255,.8)",
      fontStyle: "italic", textAlign: "center", maxWidth: "70vw",
      animation: "dialogueFadeIn .4s ease",
      boxShadow: `0 4px 24px rgba(0,0,0,.7)`,
    }}>
      <span style={{ color, marginRight: 6 }}>
        {tier === 1 ? "☀️" : tier === 2 ? "🌙" : "💀"}
      </span>
      {text}
    </div>
  );
};// ═══════════════════════════════════════════════════════════════
// SHELLQUEST RPG — NEW BLOCK 11
// ENHANCED BATTLE WRAPPER · ROOT APP (single definition)
// ═══════════════════════════════════════════════════════════════

// Wraps BattleArena with post-battle overlays (level-up, victory, defeat, evolution)
export const EnhancedBattleArena=({state,dispatch})=>{
  const {player,battle}=state;
  if(!player||!battle) return null;

  const [pendingVictory,setPendingVictory]=useState(null);
  const [pendingLevelUp,setPendingLevelUp]=useState(null);
  const [pendingEvo,setPendingEvo]=useState(null);
  const [pendingDefeat,setPendingDefeat]=useState(null);
  const prevPhase=useRef(battle.phase);

  // Detect phase transitions to trigger overlays
  useEffect(()=>{
    const prev=prevPhase.current;
    const cur=battle.phase;
    prevPhase.current=cur;
    // Victory just triggered — compute results for overlay
    if(prev!=="VICTORY"&&cur==="VICTORY") {
      const enemy=battle.enemy;
      const {player:pp,lvs}=applyLvUp({...player},enemy.xpReward||0);
      const drops=[];
      (enemy.drops||[]).forEach(d=>{
        if(Math.random()<d.ch&&player.inventory.length<30){
          const it=ITEMS[d.id]; if(it) drops.push({uuid:makeUUID(),...it});
        }
      });
      if(lvs.length){
        // Check pet evolution
        let evo=null;
        if(player.activePetId){
          const petInst=player.party?.find(p=>p.id===player.activePetId);
          if(petInst){
            const updPet={...petInst,xp:(petInst.xp||0)+Math.floor(enemy.xpReward*.5)};
            const {evolved,evolutionData,pet:evoPet}=petLevelUp(updPet);
            if(evolved) evo={pet:evoPet,evolutionData};
          }
        }
        setPendingVictory({enemy,xp:enemy.xpReward,gold:enemy.goldReward,drops});
        setPendingLevelUp({player:pp,prev:player,level:pp.level});
        if(evo) setPendingEvo(evo);
      } else {
        setPendingVictory({enemy,xp:enemy.xpReward,gold:enemy.goldReward,drops});
      }
    }
    if(prev!=="DEFEAT"&&cur==="DEFEAT"){
      setPendingDefeat({enemy:battle.enemy});
    }
  },[battle.phase]);

  return(
    <>
      {/* Main battle (always rendered as base layer) */}
      <BattleArena state={state} dispatch={dispatch}/>

      {/* Post-battle overlays — render above BattleArena */}
      {pendingVictory&&(
        <VictoryFanfare
          enemy={pendingVictory.enemy}
          xpGained={pendingVictory.xp}
          goldGained={pendingVictory.gold}
          drops={pendingVictory.drops}
          leveledUp={!!pendingLevelUp}
          newLevel={pendingLevelUp?.level}
          onClose={()=>{
            setPendingVictory(null);
            if(!pendingLevelUp&&!pendingEvo) dispatch({type:"RETURN_WORLD"});
          }}/>
      )}
      {pendingLevelUp&&!pendingVictory&&(
        <LevelUpScreen
          player={pendingLevelUp.player}
          prevPlayer={pendingLevelUp.prev}
          newLevel={pendingLevelUp.level}
          onClose={()=>{
            setPendingLevelUp(null);
            if(!pendingEvo) dispatch({type:"RETURN_WORLD"});
          }}/>
      )}
      {pendingEvo&&!pendingLevelUp&&!pendingVictory&&(
        <EvolutionCutscene
          pet={pendingEvo.pet}
          evolutionData={pendingEvo.evolutionData}
          onClose={()=>{setPendingEvo(null);dispatch({type:"RETURN_WORLD"});}}/>
      )}
      {pendingDefeat&&(
        <DefeatScreen
          enemy={pendingDefeat.enemy}
          goldLost={10}
          onClose={()=>{setPendingDefeat(null);dispatch({type:"RETURN_WORLD"});}}/>
      )}
    </>
  );
};

// ─── Single useGlobalCSS ───────────────────────────────────────
function useGlobalCSS(){
  useEffect(()=>{
    if(document.getElementById("sq-css")) return;
    const el=document.createElement("style");
    el.id="sq-css"; el.textContent=GLOBAL_CSS;
    document.head.appendChild(el);
    return()=>document.getElementById("sq-css")?.remove();
  },[]);
}

// ═══════════════════════════════════════════════════════════════
// ROOT APP — single default export
// ═══════════════════════════════════════════════════════════════
export default function App(){
  useGlobalCSS();
  const [state,dispatch]=useReducer(reducer,INITIAL_STATE);
  const {w:winW,h:winH}=useWindowDimensions();

  // World init
  useEffect(()=>{
    if(state.screen!=="WORLD"||state.isInitialized||!state.player) return;
    const ents=generateEntities(state.player.zx,state.player.zy,state.player.level);
    dispatch({type:"INIT_WORLD",payload:{entities:ents}});
  },[state.screen,state.isInitialized,state.player]);

  // Zone transition done
  useEffect(()=>{
    if(!state.zoneTransitioning) return;
    const t=setTimeout(()=>dispatch({type:"ZONE_DONE"}),500);
    return()=>clearTimeout(t);
  },[state.zoneTransitioning]);

  // Tick
  const tickRef=useRef(null);
  useEffect(()=>{
    if(state.screen!=="WORLD"||!state.isInitialized){clearInterval(tickRef.current);return;}
    tickRef.current=setInterval(()=>dispatch({type:"TICK"}),1000);
    return()=>clearInterval(tickRef.current);
  },[state.screen,state.isInitialized]);

  // Toast auto-clear
  const toastRef=useRef(null);
  useEffect(()=>{
    if(!state.toast) return;
    clearTimeout(toastRef.current);
    toastRef.current=setTimeout(()=>dispatch({type:"CLR_TOAST"}),2800);
    return()=>clearTimeout(toastRef.current);
  },[state.toast]);

  // External systems
  const {event:worldEvent,timeLeft:eventTimeLeft}=useWorldEvent(state.tick);
  const {currentAchievement,dismiss:dismissAchievement}=useAchievements(state);

  // Zone flavor on travel
  const [showFlavor,setShowFlavor]=useState(false);
  const prevZone=useRef({zx:0,zy:0});
  useEffect(()=>{
    if(!state.player) return;
    if(state.player.zx!==prevZone.current.zx||state.player.zy!==prevZone.current.zy){
      prevZone.current={zx:state.player.zx,zy:state.player.zy};
      setShowFlavor(true);
      setTimeout(()=>setShowFlavor(false),4000);
    }
  },[state.player?.zx,state.player?.zy]);

  const [showWorldMap,setShowWorldMap]=useState(false);

  const activePet=useMemo(()=>{
    if(!state.player?.activePetId) return null;
    const base=PETS[state.player.activePetId];
    if(base){
      const inst=state.player.party?.find(p=>p.id===base.id);
      return inst?{...base,hp:inst.hp,maxHp:inst.maxHp??base.hp,level:inst.level,xp:inst.xp||0}
        :{...base,maxHp:base.hp,xp:0};
    }
    const inst=state.player.party?.find(p=>p.id===state.player.activePetId);
    if(inst) return{...inst,color:"#aaa",emoji:inst.emoji||"🐾"};
    return null;
  },[state.player?.activePetId,state.player?.party]);

  const stats=useMemo(()=>
    state.player?effStats(state.player):{effAtk:20,effDef:10,effMaxHp:100,effMaxMp:80,critChance:.08},
    [state.player]);

  const zm=state.player?getZoneMeta(state.player.zx,state.player.zy):null;

  return(
    <div style={{position:"fixed",top:0,left:0,width:winW,height:winH,
      overflow:"hidden",background:"#060612",fontFamily:T.fontB}}>

      {state.screen==="PRELOAD"&&(
        <Preloader onDone={()=>dispatch({type:"PRELOAD_DONE"})}/>
      )}

      {state.screen==="CREATE"&&(
        <CharCreate onStart={(name,avatar)=>
          dispatch({type:"INIT_PLAYER",payload:{name,avatar}})}/>
      )}

      {state.screen==="WORLD"&&(
        <>
          {!state.isInitialized&&<LoadingScreen/>}
          {state.isInitialized&&(
            <>
              {/* Map — no pointer-events restriction on root */}
              <WorldMap state={state} dispatch={dispatch}/>

              {/* Atmosphere layers — pointer-events: none internally */}
              <WeatherLayer zx={state.player.zx} zy={state.player.zy} tick={state.tick}/>
              <DayNightLayer zx={state.player.zx} zy={state.player.zy}/>
              <WorldAmbient zx={state.player.zx} zy={state.player.zy}/>

              {/* Ghost HUD — pointer-events: none wrapper, auto on buttons */}
              <HUD player={state.player} stats={stats}
                activePet={activePet} dispatch={dispatch}
                financeStreak={state.financeStreakCount}
                totalAnswered={state.totalFinanceAnswered}/>

              {/* Mini-map */}
              <MiniMap player={state.player} entities={state.entities}
                tileMap={getZoneTileMap(state.player.zx,state.player.zy)}
                statics={zm?.statics||[]}/>

              {/* Daily challenge */}
              <DailyChallengeCard state={state} dispatch={dispatch}/>

              {/* World event banner */}
              <WorldEventBanner event={worldEvent} timeLeft={eventTimeLeft}/>

              {/* World map button */}
              <div className="hud-interactive" style={{
                position:"absolute",bottom:70,left:"50%",transform:"translateX(-50%)",
                zIndex:8005}}>
                <button className="gbtn" onClick={()=>setShowWorldMap(true)} style={{
                  background:"rgba(6,4,18,.9)",border:"1.5px solid rgba(255,255,255,.12)",
                  borderRadius:12,padding:"5px 12px",
                  display:"flex",alignItems:"center",gap:5,
                  backdropFilter:"blur(12px)",color:"#aaa",cursor:"pointer"}}>
                  <span style={{fontSize:13}}>🗺️</span>
                  <span style={{fontFamily:T.fontB,fontSize:9,fontWeight:700}}>World Map</span>
                </button>
              </div>

              {/* Zone flavor */}
              {showFlavor&&<ZoneFlavorToast zx={state.player.zx} zy={state.player.zy}/>}

              {/* Overlay modals */}
              <OverlayStack state={state} dispatch={dispatch}/>

              {/* World map modal */}
              {showWorldMap&&(
                <WorldMapScreen player={state.player} questProgress={state.questProgress}
                  onClose={()=>setShowWorldMap(false)}/>
              )}

              {/* NPC Dialogue */}
              {state.activeDialogue&&(
                <DialogueBox npcId={state.activeDialogue.npcId}
                  onClose={()=>dispatch({type:"CLOSE_DIALOGUE"})}/>
              )}
            </>
          )}
        </>
      )}

      {state.screen==="TRANSITION_VFX"&&(
        <TransitionVFX onDone={()=>dispatch({type:"TRANSITION_DONE"})}/>
      )}

      {state.screen==="BATTLE"&&state.battle&&(
        <>
          {/* EnhancedBattleArena handles post-battle overlays */}
          <EnhancedBattleArena state={state} dispatch={dispatch}/>
          {/* Finance modal floats above everything */}
          {state.showFinanceModal&&state.financeScenario&&(
            <FinanceModal
              question={state.financeScenario}
              type={state.pendingTame?"tame":"spell"}
              onAnswer={answer=>dispatch({
                type:state.pendingTame?"ANSWER_TAME_FINANCE":"ANSWER_FINANCE",
                payload:{answer},
              })}
              onClose={()=>dispatch({type:"CLOSE_FINANCE_MODAL"})}/>
          )}
        </>
      )}

      {/* Achievements */}
      {currentAchievement&&(
        <AchievementPopup achievement={currentAchievement} onDone={dismissAchievement}/>
      )}

      {/* Global toast */}
      {state.toast&&<ToastBanner msg={state.toast.msg} t={state.toast.t}/>}
    </div>
  );
}