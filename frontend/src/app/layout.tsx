import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers/Providers";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "FTUSDT - FLASHTRON USDT Token",
  description: "A secure and efficient TRC-20 token built on the TRON blockchain",
  keywords: ["FTUSDT", "FLASHTRON", "TRON", "TRC-20", "Cryptocurrency", "Token"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body className={`${inter.className} h-full antialiased`}>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
