using ManejoPresupuestos.Models;

namespace ManejoPresupuestos.Servicios
{
    public interface IServicioCosteoTarifas
    {
        Task<CosteoResumenDto> CalcularMaterialPorInventario(
            IEnumerable<ConsumoInventarioDto> consumos,
            int loginId,
            int? impresoraId = null
        );
    }

    public class ServicioCosteoTarifas : IServicioCosteoTarifas
    {
        private readonly IRepositorioTarifas repositorioTarifas;

        public ServicioCosteoTarifas(IRepositorioTarifas repositorioTarifas)
        {
            this.repositorioTarifas = repositorioTarifas;
        }

        public async Task<CosteoResumenDto> CalcularMaterialPorInventario(
            IEnumerable<ConsumoInventarioDto> consumos,
            int loginId,
            int? impresoraId = null)
        {
            var resumen = new CosteoResumenDto();
            resumen.Detalles ??= new List<CosteoDetalleDto>();

            string monedaBase = "MXN";

            void ValidarMoneda(string? moneda)
            {
                var m = string.IsNullOrWhiteSpace(moneda) ? "MXN" : moneda.Trim().ToUpperInvariant();
                if (resumen.Detalles.Count == 0) monedaBase = m;

                if (m != monedaBase)
                    throw new InvalidOperationException($"Moneda mezclada en tarifas: {monedaBase} vs {m}.");
            }

            var consumosList = (consumos ?? Enumerable.Empty<ConsumoInventarioDto>())
                .Where(x => x.InventarioId > 0 && x.CantidadUsada > 0)
                .ToList();

            // ==========================================
            // A) MATERIAL_UNIT (por consumo: monto * cantidadUsada)
            // ==========================================
            foreach (var c in consumosList)
            {
                const string concepto = "MATERIAL_UNIT";

                var tarifasRaw = await repositorioTarifas.ObtenerAplicables(
                    tarifaConceptoCodigo: concepto,
                    impresoraId: null,
                    inventarioId: c.InventarioId,
                    loginId: loginId
                );

                var tarifas = (tarifasRaw ?? Enumerable.Empty<TarifaAplicableDto>())
                    .OrderBy(x => x.TarifaOrden)
                    .ThenBy(x => x.TarifaId);

                foreach (var t in tarifas)
                {
                    ValidarMoneda(t.Moneda);

                    var subtotal = t.Monto * c.CantidadUsada;

                    resumen.Detalles.Add(new CosteoDetalleDto
                    {
                        ConceptoCodigo = concepto,
                        InventarioId = c.InventarioId,
                        ImpresoraId = null,

                        TarifaId = t.TarifaId,
                        TarifaNombre = t.TarifaNombre ?? "",
                        TarifaOrden = t.TarifaOrden,

                        MontoTarifa = t.Monto,
                        Cantidad = c.CantidadUsada,
                        Subtotal = subtotal,
                        Moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant()
                    });
                }
            }

            // ==========================================
            // B) MATERIAL_GENERAL (flat por inventario específico)
            //    Se suma 1 vez por InventarioId que se haya usado
            // ==========================================
            foreach (var c in consumosList)
            {
                const string concepto = "MATERIAL_GENERAL";

                var tarifasRaw = await repositorioTarifas.ObtenerAplicables(
                    tarifaConceptoCodigo: concepto,
                    impresoraId: null,
                    inventarioId: c.InventarioId,
                    loginId: loginId
                );

                var tarifas = (tarifasRaw ?? Enumerable.Empty<TarifaAplicableDto>())
                    .OrderBy(x => x.TarifaOrden)
                    .ThenBy(x => x.TarifaId);

                foreach (var t in tarifas)
                {
                    // OJO: gracias a procTarifasSet, aquí solo deben venir scoped a ese inventario
                    ValidarMoneda(t.Moneda);

                    resumen.Detalles.Add(new CosteoDetalleDto
                    {
                        ConceptoCodigo = concepto,
                        InventarioId = c.InventarioId, // se liga al inventario que disparó el cargo
                        ImpresoraId = null,

                        TarifaId = t.TarifaId,
                        TarifaNombre = t.TarifaNombre ?? "",
                        TarifaOrden = t.TarifaOrden,

                        MontoTarifa = t.Monto,
                        Cantidad = 1,
                        Subtotal = t.Monto,
                        Moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant()
                    });
                }
            }

            // ==========================================
            // C) MATERIAL_GENERAL_INV_GLOBAL (flat global inventarios)
            //    Se suma 1 vez si hubo cualquier consumo de inventario
            // ==========================================
            if (consumosList.Count > 0)
            {
                const string concepto = "MATERIAL_GENERAL_INV_GLOBAL";

                var tarifasRaw = await repositorioTarifas.ObtenerAplicables(
                    tarifaConceptoCodigo: concepto,
                    impresoraId: null,
                    inventarioId: null,
                    loginId: loginId
                );

                var tarifas = (tarifasRaw ?? Enumerable.Empty<TarifaAplicableDto>())
                    .OrderBy(x => x.TarifaOrden)
                    .ThenBy(x => x.TarifaId);

                foreach (var t in tarifas)
                {
                    ValidarMoneda(t.Moneda);

                    resumen.Detalles.Add(new CosteoDetalleDto
                    {
                        ConceptoCodigo = concepto,
                        InventarioId = 0,
                        ImpresoraId = null,

                        TarifaId = t.TarifaId,
                        TarifaNombre = t.TarifaNombre ?? "",
                        TarifaOrden = t.TarifaOrden,

                        MontoTarifa = t.Monto,
                        Cantidad = 1,
                        Subtotal = t.Monto,
                        Moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant()
                    });
                }
            }

            // ==========================================
            // D) MATERIAL_GENERAL (flat por impresora específica)
            //    Se suma 1 vez por impresora usada (si viene)
            // ==========================================
            if (impresoraId.HasValue && impresoraId.Value > 0)
            {
                const string concepto = "MATERIAL_GENERAL";

                var tarifasRaw = await repositorioTarifas.ObtenerAplicables(
                    tarifaConceptoCodigo: concepto,
                    impresoraId: impresoraId.Value,
                    inventarioId: null,
                    loginId: loginId
                );

                var tarifas = (tarifasRaw ?? Enumerable.Empty<TarifaAplicableDto>())
                    .OrderBy(x => x.TarifaOrden)
                    .ThenBy(x => x.TarifaId);

                foreach (var t in tarifas)
                {
                    // OJO: gracias a procTarifasSet, aquí solo deben venir scoped a esa impresora
                    ValidarMoneda(t.Moneda);

                    resumen.Detalles.Add(new CosteoDetalleDto
                    {
                        ConceptoCodigo = concepto,
                        InventarioId = 0,
                        ImpresoraId = impresoraId.Value,

                        TarifaId = t.TarifaId,
                        TarifaNombre = t.TarifaNombre ?? "",
                        TarifaOrden = t.TarifaOrden,

                        MontoTarifa = t.Monto,
                        Cantidad = 1,
                        Subtotal = t.Monto,
                        Moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant()
                    });
                }

                // ==========================================
                // E) MATERIAL_GENERAL_PRN_GLOBAL (flat global impresoras)
                //    Se suma 1 vez si hay impresora usada
                // ==========================================
                const string conceptoPrnGlobal = "MATERIAL_GENERAL_PRN_GLOBAL";

                var prnGlobalRaw = await repositorioTarifas.ObtenerAplicables(
                    tarifaConceptoCodigo: conceptoPrnGlobal,
                    impresoraId: null,
                    inventarioId: null,
                    loginId: loginId
                );

                var prnGlobal = (prnGlobalRaw ?? Enumerable.Empty<TarifaAplicableDto>())
                    .OrderBy(x => x.TarifaOrden)
                    .ThenBy(x => x.TarifaId);

                foreach (var t in prnGlobal)
                {
                    ValidarMoneda(t.Moneda);

                    resumen.Detalles.Add(new CosteoDetalleDto
                    {
                        ConceptoCodigo = conceptoPrnGlobal,
                        InventarioId = 0,
                        ImpresoraId = impresoraId.Value,

                        TarifaId = t.TarifaId,
                        TarifaNombre = t.TarifaNombre ?? "",
                        TarifaOrden = t.TarifaOrden,

                        MontoTarifa = t.Monto,
                        Cantidad = 1,
                        Subtotal = t.Monto,
                        Moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant()
                    });
                }
            }

            resumen.Moneda = monedaBase;
            return resumen;
        }
    }
}