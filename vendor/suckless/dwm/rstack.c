// rstack.c — original dwm tile: master till vänster, stack till höger
// Modifierad så att ett ensamt fönster fyller hela ytan

void
rstack(Monitor *m)
{
    unsigned int i, n, h, mw, my, ty;
    Client *c;

    /* Räkna fönster */
    for (n = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next))
        n++;
    if (n == 0)
        return;

    /* Om bara ett fönster – fyll hela ytan */
    if (n == 1) {
        c = nexttiled(m->clients);
        resize(c, m->wx, m->wy,
               m->ww - 2 * c->bw,
               m->wh - 2 * c->bw, 0);
        return;
    }

    /* Vanlig layout: master vänster, stack höger */
    mw = m->ww * m->mfact;
    my = ty = 0;

    for (i = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), i++) {
        if (i < m->nmaster) {
            /* Master till vänster */
            h = (m->wh - my) / (MIN(n, m->nmaster) - i);
            resize(c,
                   m->wx,
                   m->wy + my,
                   mw - 2 * c->bw,
                   h - 2 * c->bw, 0);
            my += HEIGHT(c);
        } else {
            /* Stack till höger */
            h = (m->wh - ty) / (n - i);
            resize(c,
                   m->wx + mw,
                   m->wy + ty,
                   m->ww - mw - 2 * c->bw,
                   h - 2 * c->bw, 0);
            ty += HEIGHT(c);
        }
    }
}
