using ManejoPresupuestos.Models;

namespace ManejoPresupuestos.Servicios
{
    public interface IServicioCosteoTarifas
    {
        Task<CosteoResumenDto> CalcularMaterialPorInventario(IEnumerable<ConsumoInventarioDto> consumos, int loginId);
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
            int loginId)
        {
            var resumen = new CosteoResumenDto();
            resumen.Detalles ??= new List<CosteoDetalleDto>();
            var monedaBase = "MXN";

            // ============================
            // A) MATERIAL_UNIT (por consumo)
            // ============================
            foreach (var c in consumos ?? Enumerable.Empty<ConsumoInventarioDto>())
            {
                if (c.InventarioId <= 0) continue;
                if (c.CantidadUsada <= 0) continue;

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
                    var moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant();
                    if (resumen.Detalles.Count == 0) monedaBase = moneda;

                    if (moneda != monedaBase)
                        throw new InvalidOperationException($"Moneda mezclada en tarifas: {monedaBase} vs {moneda}.");

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
                        Moneda = moneda
                    });
                }
            }

            // ============================
            // B) MATERIAL_GENERAL (flat una vez)
            // ============================
            const string conceptoGeneral = "MATERIAL_GENERAL";

            var generalesRaw = await repositorioTarifas.ObtenerAplicables(
                tarifaConceptoCodigo: conceptoGeneral,
                impresoraId: null,
                inventarioId: null,
                loginId: loginId
            );

            var generales = (generalesRaw ?? Enumerable.Empty<TarifaAplicableDto>())
                .OrderBy(x => x.TarifaOrden)
                .ThenBy(x => x.TarifaId);

            foreach (var t in generales)
            {
                var moneda = string.IsNullOrWhiteSpace(t.Moneda) ? "MXN" : t.Moneda.Trim().ToUpperInvariant();
                if (resumen.Detalles.Count == 0) monedaBase = moneda;

                if (moneda != monedaBase)
                    throw new InvalidOperationException($"Moneda mezclada en tarifas: {monedaBase} vs {moneda}.");

                resumen.Detalles.Add(new CosteoDetalleDto
                {
                    ConceptoCodigo = conceptoGeneral,

                    // OJO: aquí lo ideal es NULL en DB; si tu DTO no permite null usa 0,
                    // y al guardar haces NULLIF(0) en SQL.
                    InventarioId = 0,
                    ImpresoraId = null,

                    TarifaId = t.TarifaId,
                    TarifaNombre = t.TarifaNombre ?? "",
                    TarifaOrden = t.TarifaOrden,

                    MontoTarifa = t.Monto,
                    Cantidad = 1,
                    Subtotal = t.Monto,
                    Moneda = moneda
                });
            }

            resumen.Moneda = monedaBase;
            return resumen;
        }
    }
}