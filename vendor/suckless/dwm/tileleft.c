// tileleft.c — stack till vänster, master till höger
// Modifierad så att ett ensamt fönster fyller hela ytan

void
tileleft(Monitor *m)
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

    /* Vanlig layout: stack vänster, master höger */
    mw = m->ww * (1 - m->mfact);
    my = ty = 0;

    for (i = 0, c = nexttiled(m->clients); c; c = nexttiled(c->next), i++) {
        if (i < m->nmaster) {
            /* Master till höger */
            h = (m->wh - my) / (MIN(n, m->nmaster) - i);
            resize(c,
                   m->wx + mw,
                   m->wy + my,
                   m->ww - mw - 2 * c->bw,
                   h - 2 * c->bw, 0);
            my += HEIGHT(c);
        } else {
            /* Stack till vänster */
            h = (m->wh - ty) / (n - i);
            resize(c,
                   m->wx,
                   m->wy + ty,
                   mw - 2 * c->bw,
                   h - 2 * c->bw, 0);
            ty += HEIGHT(c);
        }
    }
}
