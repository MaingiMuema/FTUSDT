/* eslint-disable @typescript-eslint/no-explicit-any */
'use client';

import { motion } from 'framer-motion';

const navigation = {
  main: [
    { name: 'About', href: '#about' },
    { name: 'Features', href: '#features' },
    { name: 'Roadmap', href: '#roadmap' },
    { name: 'Partners', href: '#partners' },
    { name: 'Documentation', href: '#docs' },
  ],
  social: [
    {
      name: 'Twitter',
      href: 'https://twitter.com/flashusdt',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
        </svg>
      ),
    },
    {
      name: 'GitHub',
      href: 'https://github.com/flashusdt',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path
            fillRule="evenodd"
            d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
            clipRule="evenodd"
          />
        </svg>
      ),
    },
    {
      name: 'Telegram',
      href: 'https://t.me/flashusdt',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path
            fillRule="evenodd"
            d="M22.05 1.577c-.393-.016-.784.08-1.117.235-.484.186-4.92 1.902-9.41 3.64-2.26.873-4.518 1.746-6.256 2.415-1.737.67-3.045 1.168-3.114 1.192-.46.16-1.082.362-1.61.984-.133.155-.267.354-.335.628s-.038.622.095.895c.265.547.714.773 1.244.976 1.76.564 3.58 1.102 5.087 1.608.503 1.388 1.6 4.366 2.053 5.581.243.694.463 1.18.688 1.525.226.345.45.553.693.681.104.054.223.09.353.109.26.037.498-.004.726-.125.076-.04.153-.094.228-.143.09-.066.18-.133.267-.203l3.312-2.416c.396 3.76.685 6.502.744 7.066.1.956.148 1.782.574 2.288.426.506 1.07.656 1.646.575.252-.035.494-.136.686-.244.315-.179.72-.545 1.89-1.718l.398-.397c.194 1.207.74 1.885 1.31 2.202.568.317 1.192.326 1.768.128.575-.198 1.098-.532 1.629-.887.627-.42 1.263-.868 1.627-1.233.056-.056.142-.137.142-.137.314-.314.237-.793-.146-1.176l-3.084-3.084c.224-1.349.424-2.647.612-3.894 1.584-10.51 2.104-14.017 2.104-14.017.116-.453.188-.877.14-1.284-.048-.407-.213-.79-.536-1.113-.322-.322-.705-.487-1.113-.535-.14-.014-.28-.02-.42-.016zM8.77 15.353l1.459 1.459-1.832 1.338-1.459-1.459 1.832-1.338zm7.845 5.605l1.457 1.457-1.832 1.338-1.457-1.457 1.832-1.338z"
            clipRule="evenodd"
          />
        </svg>
      ),
    },
    {
      name: 'Discord',
      href: 'https://discord.gg/flashusdt',
      icon: (props: any) => (
        <svg fill="currentColor" viewBox="0 0 24 24" {...props}>
          <path d="M20.317 4.492c-1.53-.69-3.17-1.2-4.885-1.49a.075.075 0 0 0-.079.036c-.21.369-.444.85-.608 1.23a18.566 18.566 0 0 0-5.487 0 12.36 12.36 0 0 0-.617-1.23A.077.077 0 0 0 8.562 3c-1.714.29-3.354.8-4.885 1.491a.07.07 0 0 0-.032.027C.533 9.093-.32 13.555.099 17.961a.08.08 0 0 0 .031.055 20.03 20.03 0 0 0 5.993 2.98.078.078 0 0 0 .084-.026c.462-.62.874-1.275 1.226-1.963.021-.04.001-.088-.041-.104a13.201 13.201 0 0 1-1.872-.878.075.075 0 0 1-.008-.125c.126-.093.252-.19.372-.287a.075.075 0 0 1 .078-.01c3.927 1.764 8.18 1.764 12.061 0a.075.075 0 0 1 .079.009c.12.098.245.195.372.288a.075.075 0 0 1-.006.125c-.598.344-1.22.635-1.873.877a.075.075 0 0 0-.041.105c.36.687.772 1.341 1.225 1.962a.077.077 0 0 0 .084.028 19.963 19.963 0 0 0 6.002-2.981.076.076 0 0 0 .032-.054c.5-5.094-.838-9.52-3.549-13.442a.06.06 0 0 0-.031-.028zM8.02 15.278c-1.182 0-2.157-1.069-2.157-2.38 0-1.312.956-2.38 2.157-2.38 1.21 0 2.176 1.077 2.157 2.38 0 1.312-.956 2.38-2.157 2.38zm7.975 0c-1.183 0-2.157-1.069-2.157-2.38 0-1.312.955-2.38 2.157-2.38 1.21 0 2.176 1.077 2.157 2.38 0 1.312-.946 2.38-2.157 2.38z" />
        </svg>
      ),
    },
  ],
};

const footerVariants = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
};

export default function Footer() {
  return (
    <motion.footer 
      className="bg-gray-900"
      initial="initial"
      whileInView="animate"
      viewport={{ once: true }}
      variants={footerVariants}
      transition={{ duration: 0.5 }}
    >
      <div className="mx-auto max-w-7xl overflow-hidden px-6 py-20 sm:py-24 lg:px-8">
        <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <h3 className="text-sm font-semibold leading-6 text-white">About FTUSDT</h3>
            <p className="mt-4 text-sm leading-6 text-gray-300">
              Flash USDT (FTUSDT) is a TRC-20 token designed for fast, secure transactions on the TRON network.
            </p>
          </div>
          <div>
            <h3 className="text-sm font-semibold leading-6 text-white">Quick Links</h3>
            <ul role="list" className="mt-4 space-y-4">
              {navigation.main.map((item) => (
                <li key={item.name}>
                  <a href={item.href} className="text-sm leading-6 text-gray-300 hover:text-white">
                    {item.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold leading-6 text-white">Resources</h3>
            <ul role="list" className="mt-4 space-y-4">
              <li>
                <a href="#" className="text-sm leading-6 text-gray-300 hover:text-white">
                  Whitepaper
                </a>
              </li>
              <li>
                <a href="#" className="text-sm leading-6 text-gray-300 hover:text-white">
                  Documentation
                </a>
              </li>
              <li>
                <a href="#" className="text-sm leading-6 text-gray-300 hover:text-white">
                  Smart Contract
                </a>
              </li>
              <li>
                <a href="#" className="text-sm leading-6 text-gray-300 hover:text-white">
                  Security Audit
                </a>
              </li>
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold leading-6 text-white">Contact</h3>
            <ul role="list" className="mt-4 space-y-4">
              <li>
                <a href="mailto:contact@flashusdt.com" className="text-sm leading-6 text-gray-300 hover:text-white">
                  contact@flashusdt.com
                </a>
              </li>
              <li>
                <a href="#" className="text-sm leading-6 text-gray-300 hover:text-white">
                  Support
                </a>
              </li>
            </ul>
          </div>
        </div>
        <div className="mt-16 flex justify-center space-x-10">
          {navigation.social.map((item) => (
            <a key={item.name} href={item.href} className="text-gray-400 hover:text-gray-500">
              <span className="sr-only">{item.name}</span>
              <item.icon className="h-6 w-6" aria-hidden="true" />
            </a>
          ))}
        </div>
        <p className="mt-10 text-center text-xs leading-5 text-gray-400">
          &copy; {new Date().getFullYear()} Flash USDT. All rights reserved.
        </p>
      </div>
    </motion.footer>
  );
}
