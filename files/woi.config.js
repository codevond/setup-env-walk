import pkg from './package'

const sitemapRoutes = require('./static/json/routes.json')
const webpack = require('webpack')
const isProd = process.env.SET_ENVIRONMENT === 'production'
const env = isProd ? require('dotenv').config({ path: 'prod.env' }) : require('dotenv').config({ path: 'staging.env' })

process.env.DEBUG = 'nuxt:*'

export default {
  ssr: true,

  server: {
     host: '0.0.0.0',
     port: 8001
   },
  /*
  ** Headers of the page
  */
  head: {
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
    ],
    link: [
      {
        rel: 'icon',
        type: 'image/png',
        sizes: '16x16',
        href: '/favicon-16x16.png'
      },
      {
        rel: 'icon',
        type: 'image/png',
        sizes: '32x32',
        href: '/favicon-32x32.png'
      }
    ],
    script: [
      {
        src: "https://code.jquery.com/jquery-3.4.1.min.js",
        type: "text/javascript",
        body: true
      },
      {
        src: 'https://cdnjs.cloudflare.com/ajax/libs/slidebars/2.0.2/slidebars.min.js',
        type: "text/javascript",
        body: true
      },
      {
        src: 'https://cdnjs.cloudflare.com/ajax/libs/fotorama/4.6.4/fotorama.min.js',
        type: "text/javascript",
        body: true
      },
      {
        src: '/js/gtmLocation.js',
        type: 'text/javascript',
        body: true
      },
      {
        src: '/js/geoIP.js',
        type: 'text/javascript',
        body: true
      },
      {
        src: 'https://www.google.com/recaptcha/api.js?onload=vueRecaptchaApiLoaded&render=explicit',
        type: "text/javascript",
        async: true,
        defer: true,
      },
    ]
  },

  env: {
    INVENTORY_API: env.parsed.INVENTORY_API,
    API_ACCESS_TOKEN: env.parsed.API_ACCESS_TOKEN,
    FEEDBACK_API: env.parsed.FEEDBACK_API,
    SET_ENVIRONMENT: env.parsed.SET_ENVIRONMENT,
    BOOKING_API: env.parsed.BOOKING_API,
    USER_API: env.parsed.USER_API,
    APP_BASE_URL: env.parsed.APP_BASE_URL,
    USER_TOKEN: env.parsed.USER_TOKEN,
    CAPTCHA_SITE_KEY: env.parsed.CAPTCHA_SITE_KEY,
  },

  /*
  ** Customize the progress-bar color
  */
  loading: { color: '#887641' },

  /*
  ** Global CSS
  */
  css: [
    '~/assets/sass/app.scss'
  ],

  /*
  ** Plugins to load before mounting the App
  */
  plugins: [
    '~/plugins/vee-validate',
    '~/plugins/img-lazy-loader',
    '~/plugins/local-storage',
    '~/plugins/svgicon',
    {
      src: '~/plugins/unveilhooks',
      ssr: false
    },
    {
      src: '~/plugins/vuex-cache',
      ssr: false
    },
    {
      src: '~/plugins/persisted-state',
      ssr: false
    },
    {
      src: '~/plugins/jquery-plugin',
      ssr: false
    }
  ],
  // enabled vue extention
  vue: {
    config: {
      productionTip: false,
      devtools: true
    }
  },
  router: {
    middleware: [
      'routes',
      'post-purchase',
      'payment-page'
    ]
  },
  sitemap: {
    gzip: true,
    exclude: [
      '/confirm',
      '/payment',
      '/post-purchase'
    ],
    routes: sitemapRoutes
  },
  /*
  ** Nuxt.js modules
  */
  modules: [
    // Doc: https://axios.nuxtjs.org/usage
    '@nuxtjs/axios',
    '@nuxtjs/pwa',
    '@nuxtjs/dotenv',
    '@nuxtjs/redirect-module',
    '@nuxtjs/sitemap',
    ['@nuxtjs/google-tag-manager',
      {
        id: 'GTM-NT7DS5N'
      }
    ]
  ],
  /*
  ** Add URLs that require a redirect to this array. Each URL should be an object. Each object accepts the params
  ** from
  ** to
  ** statuscode
  */
  redirect: [
  ],
  /*
  ** Axios module configuration
  */
  axios: {
    // See https://github.com/nuxt-community/axios-module#options
  },

  /*
  ** Build configuration
  */
  build: {
    analyze: false,
    terser: {
      terserOptions: {
        compress: {
          drop_console: true
        }
      }
    },
    vendor: [
      'jquery'
    ],
    mode: 'production',
    plugins: [
      new webpack.ProvidePlugin({
        $: 'jquery'
      })
    ],
    transpile: [
      'vue-read-more'
    ],
    /*
    ** You can extend webpack config here
    */
    extend(config, ctx) {
      // display source map as expected
      if (ctx.isClient) {
        config.devtool = '#source-map'
      }
      config.module.rules.forEach(rule => {
        if (String(rule.test) === String(/\.(png|jpe?g|gif|svg|webp)$/)) {
          // add a second loader when loading images
          rule.use.push({
            loader: 'image-webpack-loader',
            options: {
              svgo: {
                plugins: [
                  // use these settings for internet explorer for proper scalable SVGs
                  // https://css-tricks.com/scale-svg/
                  { removeViewBox: false },
                  { removeDimensions: true }
                ]
              }
            }
          })
        }
      })
      // adding the new loader as the first in the list
      config.module.rules.unshift({
        test: /\.(png|jpe?g|gif)$/,
        use: {
          loader: 'responsive-loader',
          options: {
            // disable: isDev,
            placeholder: true,
            quality: 85,
            placeholderSize: 30,
            name: 'img/[name].[hash:hex:7].[width].[ext]',
            adapter: require('responsive-loader/sharp')
          }
        }
      })
      // remove old pattern from the older loader
      config.module.rules.forEach(value => {
        if (String(value.test) === String(/\.(png|jpe?g|gif|svg|webp)$/)) {
          // reduce to svg and webp, as other images are handled above
          value.test = /\.(svg|webp)$/
          // keep the configuration from image-webpack-loader here unchanged
        }
      })
    }
  }
}
