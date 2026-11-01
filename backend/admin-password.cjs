'use strict';
// Password comes only from stdin, never command-line arguments or tracked files.
const {passwordHash}=require('./server.cjs');let input='';process.stdin.setEncoding('utf8');process.stdin.on('data',s=>{input+=s;if(input.length>512)process.exit(1)});process.stdin.on('end',()=>{const password=input.replace(/[\r\n]+$/,'');if(password.length<16){console.error('Use a password of at least 16 characters');process.exit(1)}console.log(passwordHash(password))});
