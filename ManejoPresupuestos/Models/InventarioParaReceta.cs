namespace ManejoPresupuestos.Models
{
    public class InventarioParaReceta
    {
        public int InventarioId { get; set; }
        public int InventarioMarcaId { get; set; }
        public int InventarioTipoId { get; set; }
        public int InventarioNombreId { get; set; }
        public int InventarioColorId { get; set; }
        public int InventarioUnidadId { get; set; }
        public decimal Cantidad { get; set; }
        public DateTime FechaCreacion { get; set; }

        public string InventarioMarca { get; set; }
        public string InventarioTipo { get; set; }
        public string InventarioNombre { get; set; }
        public string InventarioNombreAbreviatura { get; set; }
        public string InventarioColor { get; set; }
        public string InventarioColorAbreviatura { get; set; }
        public string InventarioUnidad { get; set; }
    }
}
