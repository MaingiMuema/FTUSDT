import Header from '@/components/Header';
import Hero from '@/components/Hero';
import Features from '@/components/Features';
import TokenStats from '@/components/TokenStats';
import RoadMap from '@/components/RoadMap';
import Partners from '@/components/Partners';
import Footer from '@/components/Footer';

export default function Home() {
  return (
    <div className="relative">
      <Header />
      <main>
        <Hero />
        <TokenStats />
        <Features />
        <RoadMap />
        <Partners />
      </main>
      <Footer />
    </div>
  );
}
