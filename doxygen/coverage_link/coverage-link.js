/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

(function(){
  function ready(fn){document.readyState==='loading'?document.addEventListener('DOMContentLoaded',fn):fn();}
  ready(function(){
    var pill=document.createElement('div'); pill.id='cov-pill';
    var a=document.createElement('a');
		a.href='@coverage_url@';
		a.target='_blank';
		a.rel='noopener';
		a.textContent='coverage tests';
    pill.appendChild(a); (document.body||document.documentElement).appendChild(pill);
  });
})();
